import { SyncOutlined } from "@ant-design/icons";
import { utils } from "ethers";
import { Button, Card, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { Address, Balance } from "../components";

// const fruitTreePng = require('../lpc-fruit-trees/fruit-trees.png');
import fruitTreePng from "../lpc-fruit-trees/fruit-trees.png";

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
  const [newPurpose, setNewPurpose] = useState("loading...");

  const treeStyle1 = {
    objectFit: "none",
    objectPosition: "0 -128px",
    width: 96,
    height: 128,
    position: "absolute",
    top: -48,
  };
  const treeStyle2 = {
    objectFit: "none",
    objectPosition: "0 -256px",
    width: 96,
    height: 128,
    position: "absolute",
    top: -48,
  };
  const treeStyle3 = {
    objectFit: "none",
    objectPosition: "0 -384px",
    width: 96,
    height: 128,
    position: "absolute",
    top: -48,
  };
  return (
    <div>
      {/*
        ⚙️ Here is an example UI that displays and sets the purpose in your smart contract:
      */}
      <div style={{ border: "1px solid #cccccc", padding: 16, margin: "auto", marginTop: 64 }}>
        <h2>Tree UI:</h2>
        <Divider />
        {/* use utils.formatEther to display a BigNumber: */}
        <h2>SEED Balance: 1 planted, 2 unplanted</h2>
        <h2>LAND Balance: 3</h2>
        <h2>FRUIT Balance: {yourLocalBalance ? utils.formatEther(yourLocalBalance) : "..."}</h2>
        <Divider />
        <Card>
          <h1>Your Property</h1>

          <div style={{ marginTop: 100, position: "relative" }}>
            <img src={fruitTreePng} style={treeStyle1} />
            <span class="gnd gnd-tilled-in-grass">
              <span id="tree-1-1"></span>
            </span>
          </div>
          <h3>Stats</h3>
          <div> X: 25 </div>
          <div> Y: 10 </div>
          <div> Health: 60% </div>
          <div> Stage: Adult </div>
          <div> Fruit: 2 </div>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              /* look how you call setPurpose on your contract: */
              /* notice how you pass a call back for tx updates too */
              const result = tx(writeContracts.YourContract.setPurpose(newPurpose), update => {
                console.log("📡 Transaction Update:", update);
                if (update && (update.status === "confirmed" || update.status === 1)) {
                  console.log(" 🍾 Transaction " + update.hash + " finished!");
                  console.log(
                    " ⛽️ " +
                      update.gasUsed +
                      "/" +
                      (update.gasLimit || update.gas) +
                      " @ " +
                      parseFloat(update.gasPrice) / 1000000000 +
                      " gwei",
                  );
                }
              });
              console.log("awaiting metamask/web3 confirm result...", result);
              console.log(await result);
            }}
          >
            Water!
          </Button>
          <Button> Fertilize! </Button>
          <Button> Harvest! </Button>
          <Button> Burn! </Button>
          <Divider />
          <div style={{ marginTop: 100, position: "relative" }}>
            <span class="gnd gnd-tilled-in-grass">
              <span id="tree-1-2"></span>
            </span>
          </div>
          <h3>Stats</h3>
          <div> X: 26 </div>
          <div> Y: 10 </div>
          <div> Health: N/A </div>
          <div> Stage: Empty Land </div>
          <div> Fruit: No fruiting tree </div>
          <Button> Plant Seed! </Button>
          <Divider />
          <div style={{ marginTop: 100, position: "relative" }}>
            <img src={fruitTreePng} style={treeStyle2} />
            <span class="gnd gnd-tilled-in-grass">
              <span id="tree-1-2"></span>
            </span>
          </div>
          <h3>Stats</h3>
          <div> X: 26 </div>
          <div> Y: 12 </div>
          <div> Health: 100 </div>
          <div> Thirst: 100 </div>
          <div> Stage: Teenager </div>
          <div> Fruit: 0 </div>

          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              /* look how you call setPurpose on your contract: */
              /* notice how you pass a call back for tx updates too */
              const result = tx(writeContracts.YourContract.setPurpose(newPurpose), update => {
                console.log("📡 Transaction Update:", update);
                if (update && (update.status === "confirmed" || update.status === 1)) {
                  console.log(" 🍾 Transaction " + update.hash + " finished!");
                  console.log(
                    " ⛽️ " +
                      update.gasUsed +
                      "/" +
                      (update.gasLimit || update.gas) +
                      " @ " +
                      parseFloat(update.gasPrice) / 1000000000 +
                      " gwei",
                  );
                }
              });
              console.log("awaiting metamask/web3 confirm result...", result);
              console.log(await result);
            }}
          >
            Water!
          </Button>
          <Button> Fertilize! </Button>
          <Button> Harvest! </Button>
          <Button> Burn! </Button>
        </Card>
        <Divider />
        <Card>
          <h2>Tree Map:</h2>
          <div>Choose LAND to buy or plant a seed</div>
          <div style={{ position: "relative" }}>
            <span class="gnd gnd-tilled-in-grass">
              <span id="tree-1-1"></span>
            </span>
            <img src={fruitTreePng} style={treeStyle1} />
            <span class="gnd gnd-tilled-in-grass"></span>
            <img src={fruitTreePng} style={treeStyle2} />
            <span class="gnd gnd-tilled-in-grass"></span>
            <img src={fruitTreePng} style={treeStyle3} />
            <span class="gnd gnd-tilled-in-grass"></span>
            <span id="t1"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
            <span class="gnd gnd-tilled-in-grass"></span>
          </div>
        </Card>
        <Divider />
        Your Address:
        <Address address={address} ensProvider={mainnetProvider} fontSize={16} />
        <Divider />
        ENS Address Example:
        <Address
          address="0x34aA3F359A9D614239015126635CE7732c18fDF3" /* this will show as austingriffith.eth */
          ensProvider={mainnetProvider}
          fontSize={16}
        />
        <Divider />
        {/* use utils.formatEther to display a BigNumber: */}
        <h2>Your Balance: {yourLocalBalance ? utils.formatEther(yourLocalBalance) : "..."}</h2>
        <div>OR</div>
        <Balance address={address} provider={localProvider} price={price} />
        <Divider />
        <div>🐳 Example Whale Balance:</div>
        <Balance balance={utils.parseEther("1000")} provider={localProvider} price={price} />
        Your Contract Address:
        <Address
          address={readContracts && readContracts.YourContract ? readContracts.YourContract.address : null}
          ensProvider={mainnetProvider}
          fontSize={16}
        />
        <Divider />
        <div style={{ margin: 8 }}>
          <Button
            onClick={() => {
              /* look how you call setPurpose on your contract: */
              tx(writeContracts.YourContract.setPurpose("🍻 Cheers"));
            }}
          >
            Set Purpose to &quot;🍻 Cheers&quot;
          </Button>
        </div>
        <div style={{ margin: 8 }}>
          <Button
            onClick={() => {
              /*
              you can also just craft a transaction and send it to the tx() transactor
              here we are sending value straight to the contract's address:
            */
              tx({
                to: writeContracts.YourContract.address,
                value: utils.parseEther("0.001"),
              });
              /* this should throw an error about "no fallback nor receive function" until you add it */
            }}
          >
            Send Value
          </Button>
        </div>
        <div style={{ margin: 8 }}>
          <Button
            onClick={() => {
              /* look how we call setPurpose AND send some value along */
              tx(
                writeContracts.YourContract.setPurpose("💵 Paying for this one!", {
                  value: utils.parseEther("0.001"),
                }),
              );
              /* this will fail until you make the setPurpose function payable */
            }}
          >
            Set Purpose With Value
          </Button>
        </div>
        <div style={{ margin: 8 }}>
          <Button
            onClick={() => {
              /* you can also just craft a transaction and send it to the tx() transactor */
              tx({
                to: writeContracts.YourContract.address,
                value: utils.parseEther("0.001"),
                data: writeContracts.YourContract.interface.encodeFunctionData("setPurpose(string)", [
                  "🤓 Whoa so 1337!",
                ]),
              });
              /* this should throw an error about "no fallback nor receive function" until you add it */
            }}
          >
            Another Example
          </Button>
        </div>
      </div>

      {/*
        📑 Maybe display a list of events?
          (uncomment the event and emit line in YourContract.sol! )
      */}
      <div style={{ width: 600, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
        <h2>Events:</h2>
        <List
          bordered
          dataSource={setPurposeEvents}
          renderItem={item => {
            return (
              <List.Item key={item.blockNumber + "_" + item.sender + "_" + item.purpose}>
                <Address address={item[0]} ensProvider={mainnetProvider} fontSize={16} />
                {item[1]}
              </List.Item>
            );
          }}
        />
      </div>
    </div>
  );
}
