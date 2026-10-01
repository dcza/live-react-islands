import { useState } from "react";

// Expensive computation for SSR cache demo
function expensiveSSRComputation() {
  if (typeof window !== 'undefined') return 0; // Skip on client

  // Simulate expensive work (fibonacci)
  function fib(n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2);
  }

  return fib(30); // Takes ~10-50ms per render
}

const ExpensiveCounter = ({ id, pushEvent, count, title }) => {
  // This makes SSR expensive - demonstrates caching benefit
  const ssrWork = expensiveSSRComputation();

  const [localCount, setLocalCount] = useState(0);

  const handleServerIncrement = () => {
    pushEvent("increment", {});
  };

  const handleLocalIncrement = () => {
    setLocalCount((prev) => prev + 1);
  };

  return (
    <div className="bg-white rounded border border-blue-200 shadow-sm overflow-hidden">
      {/* Compact Header */}
      <div className="bg-gradient-to-r from-blue-50 to-purple-50 px-2 py-1 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-medium text-gray-800">{title}</h4>
          <span className="px-1.5 py-0.5 rounded text-[10px] font-medium bg-emerald-100 text-emerald-700">
            #{id}
          </span>
        </div>
      </div>

      {/* Compact Content */}
      <div className="p-2">
        <div className="flex gap-2">
          {/* Server Count */}
          <div className="flex-1 bg-blue-50 rounded p-1.5 border border-blue-200">
            <div className="text-xs text-blue-600 mb-0.5">Server</div>
            <div className="text-lg font-bold text-blue-700">{count}</div>
            <button
              onClick={handleServerIncrement}
              className="w-full mt-1 py-1 px-2 rounded text-[10px] font-medium bg-blue-500 hover:bg-blue-600 text-white"
            >
              +1
            </button>
          </div>

          {/* Local Count */}
          <div className="flex-1 bg-purple-50 rounded p-1.5 border border-purple-200">
            <div className="text-xs text-purple-600 mb-0.5">Local</div>
            <div className="text-lg font-bold text-purple-700">{localCount}</div>
            <button
              onClick={handleLocalIncrement}
              className="w-full mt-1 py-1 px-2 rounded text-[10px] font-medium bg-purple-500 hover:bg-purple-600 text-white"
            >
              +1
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExpensiveCounter;
