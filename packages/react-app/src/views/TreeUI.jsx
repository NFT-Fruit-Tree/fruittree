import { SyncOutlined } from "@ant-design/icons";
import { utils } from "ethers";
import { Button, Card, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { Address, Balance } from "../components";

// const fruitTreePng = require('../lpc-fruit-trees/fruit-trees.png');
import fruitTreePng from "../lpc-fruit-trees/fruit-trees.png";
import NavBar from "../components/treeui/NavBar";
import SidePanel from "../components/treeui/SidePanel";
import TreeMap from "../components/treeui/TreeMap";
import ButtonBar from "../components/treeui/ButtonBar";

export default function TreeUI({
  purpose,
  setPurposeEvents,
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  price,
  tx,
  readContracts,
  writeContracts,
}) {
  return (
    <div className="h-full flex flex-col">
      <NavBar />
      <div className="grid grid-cols-4 h-full">
        <div className="col-span-1 row-span-6 h-full">
          <SidePanel />
        </div>
        <div className="col-span-3">
          <div className="">
            <TreeMap />
            <TreeMap />
            <TreeMap />
            <TreeMap />
          </div>
          <div className="">
            <ButtonBar />
          </div>
        </div>
      </div>
    </div>
  );
}
