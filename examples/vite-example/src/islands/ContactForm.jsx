import { useForm } from "@live-react-islands/core";

const ContactForm = ({ id, pushEvent, form }) => {
  const { getFieldProps, getError, isRequired, handleSubmit, values } = useForm(
    form,
    {
      onChange: (values) => pushEvent("validate", values),
      onSubmit: (values) => pushEvent("submit", values),
    }
  );

  const inputClass = (name) =>
    `w-full px-4 py-2 border rounded-lg bg-white text-gray-900 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors ${
      getError(name)
        ? "border-red-400 bg-red-50"
        : "border-gray-300 hover:border-gray-400"
    }`;

  const labelClass = "block text-sm font-medium text-gray-700 mb-1";

  return (
    <div className="mx-auto max-w-[500px] relative bg-white rounded-lg border-2 border-blue-200 shadow-lg overflow-hidden">
      {/* Header */}
      <div className="bg-linear-to-r from-blue-50 to-purple-50 px-4 py-3 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-linear-to-r from-blue-500 to-purple-500 rounded-lg flex items-center justify-center">
              <span className="text-white text-sm font-bold">📝</span>
            </div>
            <div>
              <h4 className="font-medium text-gray-800 text-sm">
                Contact Form
              </h4>
              <p className="text-xs text-gray-600">
                React form with server-side validation
              </p>
            </div>
          </div>
          <div className="px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
            #{id}
          </div>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="p-4 space-y-4">
        {/* Name */}
        <div>
          <label className={labelClass}>
            Name {isRequired("name") && <span className="text-red-500">*</span>}
          </label>
          <input
            type="text"
            {...getFieldProps("name")}
            className={inputClass("name")}
            placeholder="Your name"
          />
          {getError("name") && (
            <p className="mt-1 text-sm text-red-600">{getError("name")}</p>
          )}
        </div>

        {/* Email */}
        <div>
          <label className={labelClass}>
            Email{" "}
            {isRequired("email") && <span className="text-red-500">*</span>}
          </label>
          <input
            type="email"
            {...getFieldProps("email")}
            className={inputClass("email")}
            placeholder="you@example.com"
          />
          {getError("email") && (
            <p className="mt-1 text-sm text-red-600">{getError("email")}</p>
          )}
        </div>

        {/* Message */}
        <div>
          <label className={labelClass}>
            Message{" "}
            {isRequired("message") && <span className="text-red-500">*</span>}
          </label>
          <textarea
            {...getFieldProps("message")}
            rows={4}
            className={inputClass("message")}
            placeholder="Your message (min 10 characters)"
          />
          {getError("message") && (
            <p className="mt-1 text-sm text-red-600">{getError("message")}</p>
          )}
        </div>

        {/* Subscribe checkbox */}
        <div className="flex items-center space-x-2">
          <input
            type="checkbox"
            id={`${id}-subscribe`}
            {...getFieldProps("subscribe")}
            className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
          />
          <label
            htmlFor={`${id}-subscribe`}
            className="text-sm text-gray-700 cursor-pointer"
          >
            Subscribe to newsletter
          </label>
        </div>

        {/* Submit */}
        <button
          type="submit"
          className="w-full py-2.5 px-4 rounded-lg text-sm font-medium transition-all duration-200 bg-linear-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white shadow-sm hover:shadow-md"
        >
          Send Message
        </button>

        {/* Debug: Current Values */}
        <div className="pt-3 border-t border-gray-200">
          <p className="text-xs font-medium text-gray-500 mb-1">
            Form State (debug):
          </p>
          <pre className="bg-gray-100 p-2 rounded text-xs text-gray-700 overflow-auto">
            {JSON.stringify(values, null, 2)}
          </pre>
        </div>
      </form>
    </div>
  );
};

export default ContactForm;
