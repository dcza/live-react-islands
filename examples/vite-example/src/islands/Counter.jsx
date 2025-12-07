import { useState } from "react";

const Counter = ({ id, pushEvent, count = 0 }) => {
  console.log("Rendering Island: ", id);

  const [localCount, setLocalCount] = useState(0);

  const handleServerIncrement = () => {
    pushEvent("increment", {});
  };

  const handleLocalIncrement = () => {
    setLocalCount((prev) => prev + 1);
  };

  return (
    <div
      className={`mx-auto w-[500px] relative bg-white rounded-lg border-2 transition-all duration-300 overflow-hidden ${"border-blue-200 shadow-lg"}`}
    >
      {/* React Island Header */}
      <div className="bg-linear-to-r from-blue-50 to-purple-50 px-3 py-2 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="w-6 h-6 bg-linear-to-r from-blue-500 to-purple-500 rounded-md flex items-center justify-center">
              <span className="text-white text-xs font-bold">⚛</span>
            </div>
            <div>
              <h4 className="text-left font-medium text-gray-800 text-xs">
                Counter Island
              </h4>
              <p className="text-xs text-gray-600">
                Server state in Elixir • Local state in React
              </p>
            </div>
          </div>
          <div
            className={
              "px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700"
            }
          >
            #{id}
          </div>
        </div>
      </div>

      {/* Main Content - Wide Layout */}
      <div
        className={`p-3 transition-all duration-300 ${
          true ? "opacity-100" : "opacity-60"
        }`}
      >
        <div className="grid grid-cols-2 gap-4">
          {/* Server Section */}
          <div className="space-y-2">
            {/* Server Count */}
            <div className="bg-linear-to-br from-blue-50 to-blue-100 rounded-md p-2 border border-blue-200">
              <div className="flex items-center justify-between mb-0.5">
                <span className="text-xs font-medium text-blue-600 uppercase">
                  Server
                </span>
                <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
              </div>
              <div className="text-lg font-bold text-blue-700">{count}</div>
              <div className="text-xs text-blue-600">Elixir State</div>
            </div>

            {/* Server Actions */}
            <div className="space-y-1.5">
              <button
                onClick={handleServerIncrement}
                className={`w-full py-2 px-3 rounded-md text-xs font-medium transition-all duration-200 bg-linear-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white shadow-sm hover:shadow-md`}
              >
                +1 Server
              </button>
            </div>
          </div>

          {/* Local Section */}
          <div className="space-y-2">
            {/* Local Count */}
            <div className="bg-linear-to-br from-purple-50 to-purple-100 rounded-md p-2 border border-purple-200">
              <div className="flex items-center justify-between mb-0.5">
                <span className="text-xs font-medium text-purple-600 uppercase">
                  Local
                </span>
                <div className="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
              </div>
              <div className="text-lg font-bold text-purple-700">
                {localCount}
              </div>
              <div className="text-xs text-purple-600">React State</div>
            </div>

            {/* Local Actions */}
            <div className="space-y-1.5">
              <button
                onClick={handleLocalIncrement}
                className={`w-full py-2 px-3 rounded-md text-xs font-medium transition-all duration-200 bg-linear-to-r from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700 text-white shadow-sm hover:shadow-md`}
              >
                +1 Local
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Counter;
