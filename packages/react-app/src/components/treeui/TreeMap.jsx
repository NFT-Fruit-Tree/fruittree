import React from "react";

const TreeMap = () => {
  return (
    <div className="bg-green-600 flex flex-row gap-12 p-12">
      {[1, 2, 4, 5, 6, 7, 8].map(number => {
        return <div className="h-24 bg-white w-24 rounded-full border"></div>;
      })}
    </div>
  );
};

export default TreeMap;
