import { useState, useEffect, useCallback, useRef } from "react";

export interface FormProps {
  /** Internal: prop name for event routing (set by server) */
  __prop?: string;
  types?: Record<string, string>;
  required?: string[];
  values: Record<string, any>;
  errors: Record<string, string[]>;
  isValid?: boolean;
  version?: number;
}

export type PushEventFn = (event: string, payload: Record<string, any>) => void;

export interface FieldProps {
  name: string;
  value: any;
  checked?: boolean;
  onChange: (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
    >
  ) => void;
}

export interface UseFormReturn {
  /** Current form field values */
  values: Record<string, any>;
  /** Current form errors by field name */
  errors: Record<string, string[]>;
  /** Field types from schema */
  types: Record<string, string>;
  /** Required field names */
  required: string[];
  /** Field names that have been modified by the user */
  touched: string[];
  /** Get props to spread on an input element */
  getFieldProps: (name: string) => FieldProps;
  /** Get the first error message for a field */
  getError: (name: string) => string | undefined;
  /** Check if a field is required */
  isRequired: (name: string) => boolean;
  /** Check if a field has been modified by the user */
  isTouched: (name: string) => boolean;
  /** Set a field value programmatically */
  setField: (name: string, value: any) => void;
  /** Handle form submission */
  handleSubmit: (e?: React.FormEvent) => void;
  /** Reset form to server values */
  reset: () => void;
  /**
   * True when the server hasn't acknowledged the latest client changes.
   * Use this to show a syncing indicator (e.g., spinner, "Validating...").
   */
  isSyncing: boolean;
  /**
   * True only when form is valid AND fully synced with server.
   * Use this to enable/disable the submit button.
   * This is the "Validation Lock" - users cannot submit until server confirms validity.
   */
  isValid: boolean;
  /** Current local version counter */
  localVersion: number;
  /** Last acknowledged server version */
  serverVersion: number;
}

export function useForm(
  form: FormProps,
  pushEvent?: PushEventFn
): UseFormReturn {
  // 1. Version Tracking
  // Local version increments on each field change
  // Server version comes from form.version prop
  const localVersionRef = useRef(form.version ?? 0);
  const lastSentVersionRef = useRef(0); // Prevents duplicate sends in StrictMode
  const [localVersion, setLocalVersion] = useState(form.version ?? 0);
  const serverVersion = form.version ?? 0;

  // Prop name comes from server (embedded in form data)
  const propName = form.__prop;

  // Reset local version when server sends a reset (version 0 with new schema)
  useEffect(() => {
    if (form.version === 0 && form.types) {
      localVersionRef.current = 0;
      setLocalVersion(0);
    }
  }, [form.version, form.types]);

  // 3. Persistent Schema
  // We only update these when the server explicitly sends them (usually on init)
  const [schema, setSchema] = useState({
    types: form.types ?? {},
    required: form.required ?? [],
  });

  if (form.types && form.types !== schema.types) {
    setSchema((prev) => ({ ...prev, types: form.types! }));
  }
  if (form.required && form.required !== schema.required) {
    setSchema((prev) => ({ ...prev, required: form.required! }));
  }

  // 4. Values Management
  const [localValues, setLocalValues] = useState<Record<string, any>>(
    form.values ?? {}
  );

  // 5. Touched Tracking (client-side only)
  const [touched, setTouched] = useState<string[]>([]);

  // Sync from server: Update local values when server sends updates
  useEffect(() => {
    setLocalValues((prev) => ({ ...prev, ...form.values }));
  }, [form.values]);

  // 6. Versioned Change Handler
  const setField = useCallback((name: string, value: any) => {
    // Mark field as touched
    setTouched((prev) => (prev.includes(name) ? prev : [...prev, name]));

    // Increment version BEFORE state update to avoid StrictMode double-increment
    localVersionRef.current += 1;
    const newVersion = localVersionRef.current;

    setLocalValues((prev) => {
      const next = { ...prev, [name]: value };

      // Update version state (will be batched with values update)
      setLocalVersion(newVersion);

      // Only send event once per version (prevents duplicate sends in StrictMode)
      if (lastSentVersionRef.current < newVersion) {
        lastSentVersionRef.current = newVersion;

        pushEvent?.("lri_form", {
          event: "validate",
          prop: propName,
          attrs: next,
          _v: newVersion,
        });
      }

      return next;
    });
  }, [propName]);

  // 6. Identity-Stable Field Props
  const getFieldProps = useCallback(
    (name: string): FieldProps => {
      const type = schema.types[name];
      const value = localValues[name];

      const base = { name };

      if (type === "boolean" || type === "bool") {
        return {
          ...base,
          checked: !!value,
          value: undefined as any,
          onChange: (e) =>
            setField(name, (e.target as HTMLInputElement).checked),
        };
      }

      return {
        ...base,
        value: value ?? "",
        onChange: (e) => setField(name, e.target.value),
      };
    },
    [localValues, schema.types, setField]
  );

  const getError = useCallback(
    (name: string) => form.errors?.[name]?.[0],
    [form.errors]
  );

  const isRequired = useCallback(
    (name: string) => schema.required.includes(name),
    [schema.required]
  );

  const isTouched = useCallback(
    (name: string) => touched.includes(name),
    [touched]
  );

  // 7. Versioned Submit Handler
  const handleSubmit = useCallback(
    (e?: React.FormEvent) => {
      e?.preventDefault();

      // Increment version for submit as well
      localVersionRef.current += 1;
      const newVersion = localVersionRef.current;
      setLocalVersion(newVersion);

      // Only send once (prevents duplicate sends if called twice)
      if (lastSentVersionRef.current < newVersion) {
        lastSentVersionRef.current = newVersion;

        pushEvent?.("lri_form", {
          event: "submit",
          prop: propName,
          attrs: localValues,
          _v: newVersion,
        });
      }
    },
    [localValues, propName]
  );

  const reset = useCallback(() => {
    setLocalValues(form.values ?? {});
    setTouched([]);
    // Reset local version to match server
    localVersionRef.current = form.version ?? 0;
    setLocalVersion(form.version ?? 0);
  }, [form.values, form.version]);

  // 8. Derived States - The "Validation Lock"
  // isSyncing: True when client has sent changes that server hasn't acknowledged
  const isSyncing = localVersion > serverVersion;

  // isValid: True only when:
  // 1. Form is in sync (server has seen all changes)
  // 2. Server says the form is valid
  // This ensures users cannot submit until server validates the latest data
  const isValid = !isSyncing && (form.isValid ?? false);

  return {
    values: localValues,
    errors: form.errors ?? {},
    types: schema.types,
    required: schema.required,
    touched,
    getFieldProps,
    getError,
    isRequired,
    isTouched,
    setField,
    handleSubmit,
    reset,
    isSyncing,
    isValid,
    localVersion,
    serverVersion,
  };
}
