import { useState, useEffect, useCallback, useMemo, useRef } from "react";

export interface FormProps {
  types?: Record<string, string>;
  required?: string[];
  values: Record<string, any>;
  errors: Record<string, string[]>;
}

export interface UseFormOptions {
  onChange?: (values: Record<string, any>) => void;
  onSubmit?: (values: Record<string, any>) => void;
}

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

export function useForm(form: FormProps, options: UseFormOptions = {}) {
  // 1. Stable Options Ref
  // This prevents setField from needing to change when the parent re-renders
  const optionsRef = useRef(options);
  optionsRef.current = options;

  // 2. Persistent Schema
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

  // 3. Values Management
  const [localValues, setLocalValues] = useState<Record<string, any>>(
    form.values ?? {}
  );

  // Sync from server: We use a ref to track if the user is "dirty"
  // to avoid jumping the cursor if an async validation returns.
  useEffect(() => {
    setLocalValues((prev) => ({ ...prev, ...form.values }));
  }, [form.values]);

  const setField = useCallback((name: string, value: any) => {
    setLocalValues((prev) => {
      const next = { ...prev, [name]: value };
      // Call onChange via ref to avoid stale closure or dependency thrashing
      optionsRef.current.onChange?.(next);
      return next;
    });
  }, []);

  // 4. Identity-Stable Field Props
  // Memoizing this return object ensures that <Input {...getFieldProps('email')} />
  // doesn't trigger a re-render unless the specific value for 'email' changes.
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

  const handleSubmit = useCallback(
    (e?: React.FormEvent) => {
      e?.preventDefault();
      optionsRef.current.onSubmit?.(localValues);
    },
    [localValues]
  );

  const reset = useCallback(
    () => setLocalValues(form.values ?? {}),
    [form.values]
  );

  return {
    values: localValues,
    errors: form.errors ?? {},
    types: schema.types,
    required: schema.required,
    getFieldProps,
    getError,
    isRequired,
    setField,
    handleSubmit,
    reset,
  };
}
