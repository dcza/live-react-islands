const ProductCard = ({ variant = "default", slots }) => {
  const isFeatured = variant === "featured";

  return (
    <div
      className={`group relative flex flex-col transition-all duration-500 min-h-[200px]
      ${
        isFeatured
          ? "scale-105 z-10 rounded-[2rem] p-[2px] bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 shadow-2xl shadow-indigo-200"
          : "rounded-3xl border border-slate-100 bg-white shadow-xl shadow-slate-200/50 hover:-translate-y-2"
      }`}
    >
      {/* Inner Container for Featured Gradient Border Effect */}
      <div
        className={`flex flex-1 flex-col h-full w-full ${
          isFeatured ? "bg-white rounded-[calc(2rem-2px)] p-2" : "p-2"
        }`}
      >
        {/* Media: Featured gets a slightly taller aspect ratio */}
        {slots.media && (
          <div
            className={`relative overflow-hidden rounded-[22px] bg-slate-100 ${
              isFeatured ? "aspect-[4/3]" : "aspect-[4/3]"
            }`}
          >
            {/* Glossy Overlay for Featured */}
            {isFeatured && (
              <div className="absolute inset-0 z-10 bg-gradient-to-tr from-indigo-500/10 to-transparent pointer-events-none" />
            )}

            <div className="h-full w-full transition-transform duration-700 ease-out group-hover:scale-110">
              {slots.media}
            </div>

            {/* Floating Badge */}
            {slots.badge && (
              <div
                className={`absolute left-3 top-3 z-20 rounded-full px-3 py-1 text-[10px] font-black uppercase tracking-widest shadow-sm backdrop-blur-md
                ${
                  isFeatured
                    ? "bg-indigo-600 text-white"
                    : "bg-white/90 text-slate-600"
                }`}
              >
                {slots.badge}
              </div>
            )}
          </div>
        )}

        {/* Content Area */}
        <div className="flex flex-1 flex-col p-5">
          <div className="flex items-start justify-between gap-4">
            <h3
              className={`text-xl font-bold tracking-tight transition-colors 
              ${
                isFeatured
                  ? "text-slate-900 text-2xl"
                  : "text-slate-800 group-hover:text-indigo-600"
              }`}
            >
              {slots.title}
            </h3>

            {slots.price && (
              <div
                className={`rounded-2xl px-3 py-1 text-lg font-black
                ${
                  isFeatured
                    ? "bg-indigo-600 text-white"
                    : "bg-slate-900 text-white"
                }`}
              >
                {slots.price}
              </div>
            )}
          </div>

          {slots.inner_block && (
            <div
              className={`mt-3 text-sm leading-relaxed line-clamp-3 ${
                isFeatured ? "text-slate-600" : "text-slate-500"
              }`}
            >
              {slots.inner_block}
            </div>
          )}

          {/* Action Area */}
          {slots.actions && (
            <div
              className={`mt-auto pt-6 ${
                isFeatured ? "border-t border-indigo-50" : ""
              }`}
            >
              <div className="flex items-center gap-3">{slots.actions}</div>
            </div>
          )}
        </div>
      </div>

      {/* "Popular" Sparkle Tag for Featured only */}
      {isFeatured && (
        <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-[10px] font-bold py-1 px-4 rounded-full shadow-lg z-30 uppercase tracking-tighter">
          Best Value
        </div>
      )}
    </div>
  );
};

export default ProductCard;
