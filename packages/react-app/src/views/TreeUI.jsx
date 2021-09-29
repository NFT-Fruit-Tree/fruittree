import { SyncOutlined } from "@ant-design/icons";
import { utils } from "ethers";
import { Button, Card, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { Address, Balance } from "../components";

// const fruitTreePng = require('../lpc-fruit-trees/fruit-trees.png');
import fruitTreePng from '../lpc-fruit-trees/fruit-trees.png';

// stuff we might need from App.jsx
// import { Transactor } from "./helpers";
import {
  useBalance,
  useContractLoader,
  useContractReader,
  useGasPrice,
  useOnBlock,
  useUserProviderAndSigner,
} from "eth-hooks";
/*
import {
  useEventListener,
} from "eth-hooks/events/useEventListener";
import { useContractConfig } from "./hooks"
*/

const ST_SEED = 'Seed'; // 0;
const ST_ADULT = 'Adult'; // 5;
function mass2stage(m) {
	if (m < 100) return ST_SEEd;
	return ST_ADULT;
}

const speciesNames = ['Apple', 'Citrus', 'Cocos', 'Banana', 'Pine', 'XXX', 'YYY', 'Enneftree'];
function species2name(speciesIdx) {
	return speciesNames[speciesIdx];
}

//export default
function TreeCard({
	idx,
  address,
  mainnetProvider,
  localProvider,
  tx,
  readContracts,
  writeContracts,
}) {
  const treeStyle1 = {objectFit: 'none', objectPosition: '0 -128px', width: 96, height: 128, position: 'absolute', top: -48};
  const treeStyle2 = {objectFit: 'none', objectPosition: '0 -256px', width: 96, height: 128, position: 'absolute', top: -48};
  const treeStyle3 = {objectFit: 'none', objectPosition: '0 -384px', width: 96, height: 128, position: 'absolute', top: -48};
  const treeStyleCocos = {objectFit: 'none', objectPosition: '0 -1024px', width: 96, height: 128, position: 'absolute', top: -48};
console.log(address, idx);
	const seedIdObj = useContractReader(readContracts, "Seed", "tokenOfOwnerByIndex", [address, idx]);
	const seedId = seedIdObj ? seedIdObj.toNumber() : -1;
	const species = 7; // TODO useContractReader(readContracts, "Seed", "species", [seedId]);
	const speciesName = species2name(species);
	const mass = 100; // TODO useContractReader(readContracts, "Seed", "mass", [seedId]);
	const fruitMass = 100; // TODO useContractReader(readContracts, "Seed", "mass", [seedId]);
	const fruitCount = Math.floor(fruitMass / 10);

	const treeStyle = treeStyleCocos; // [treeStyle1, treeStyle2, treeStyle3][species % 3]; // XXX just show some variation

	return (
		<Card>
          <div style={{marginTop: 100, position: 'relative'}}>
            <img src={fruitTreePng} style={treeStyle} />
            <span className="gnd gnd-tilled-in-grass"><span id={"tree-1-" + idx}></span></span>
          </div>
					<h3>Stats</h3>
					<div> ID: { seedId }</div>
					<div> Species: { speciesName }</div>
					<div> X: { seedId % 32 } </div>
					<div> Y: { Math.floor(seedId / 32) }</div>
					<div> Health: 60% TODO Thirst?</div>
					<div> Stage: { mass2stage(mass) }</div>
					<div> Fruit: { fruitCount } </div>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.water(), update => {
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
          <Button> _Fertilize! </Button>
          <Button> _Harvest! </Button>
          <Button> _Burn! </Button>
					<Divider />
		</Card>
	);
}


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

	const landSupply = useContractReader(readContracts, "Land", "totalSupply");
	const fruitTotalSupply = useContractReader(readContracts, "Fruit", "totalSupply");
	const fruitBalance = useContractReader(readContracts, "Fruit", "balanceOf", [address]);
	const seedBalance = useContractReader(readContracts, "Seed", "balanceOf", [address]);
/*

Show My Balances of: Seeds (Trees), Land Plots, Fruits
- balanceOf

For each Seed, show:
- DNA + show traits based on DNA
- species (from DNA)
- mass/stage - dead or not
- fruit mass/count
- last watered, current water level
- last fertilized
- don't show factors, let user figure them out

*/
	// iterate over all tokenOfOwnerByIndex from 0 to balanceOf
	// XXX quick hack - load max 5 trees
	const seedTokensOfOwnerByIndex = [...Array(Math.min(5, seedBalance ? seedBalance.toNumber() : 0)).keys()];

  const treeStyle1 = {objectFit: 'none', objectPosition: '0 -128px', width: 96, height: 128, position: 'absolute', top: -48};
  const treeStyle2 = {objectFit: 'none', objectPosition: '0 -256px', width: 96, height: 128, position: 'absolute', top: -48};
  const treeStyle3 = {objectFit: 'none', objectPosition: '0 -384px', width: 96, height: 128, position: 'absolute', top: -48};
  return (
    <div>
      {/*
        ⚙️ Here is an example UI that displays and sets the purpose in your smart contract:
      */}
      <div style={{ border: "1px solid #cccccc", padding: 16, margin: "auto", marginTop: 64 }}>
        <h2>Tree UI:</h2>
        <Divider />
        {/* use utils.formatEther to display a BigNumber: */}
				<h2>SEED Balance: 1 planted, 2 unplanted TODO traverse my seed tokens and count which have seed stage</h2>
				XXX but TreeCard component loads tree data as component state without bubbling up...
				<h2>LAND Balance (temp showing totalSupply): {landSupply ? landSupply.toString() : '...'}</h2>
        <h2>FRUIT Balance: {fruitBalance ? utils.formatEther(fruitBalance) : "..."} of totalSupply {fruitTotalSupply ? utils.formatEther(fruitTotalSupply) : '...'}</h2>
        <Divider />
        <Card>
          <h1>Your Property: Iterate over Seed tokens, then empty Land</h1>

					{
					  seedTokensOfOwnerByIndex.map(idx => <TreeCard key={'treecard-'+idx}
							idx={idx}
							address={address}
							readContracts={readContracts}
							writeContracts={writeContracts}
							tx={tx}
						 />
					  )
				  }
				</Card>
      	<Divider />
				<Card>
        	<h2>Tree Map:</h2>
					<div>Choose LAND to buy or plant a seed</div>
          <div style={{position: 'relative'}}>
            <span className="gnd gnd-tilled-in-grass"><span id="tree-1-1"></span></span>
            <img src={fruitTreePng} style={treeStyle1} />
            <span className="gnd gnd-tilled-in-grass"></span>
            <img src={fruitTreePng} style={treeStyle2} />
            <span className="gnd gnd-tilled-in-grass"></span>
            <img src={fruitTreePng} style={treeStyle3} />
            <span className="gnd gnd-tilled-in-grass"></span>
            <span id="t1"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
            <span className="gnd gnd-tilled-in-grass"></span>
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

      <div style={{ width: 600, margin: "auto", marginTop: 32, paddingBottom: 256 }}>
        <Card>
          Check out all the{" "}
          <a
            href="https://github.com/austintgriffith/scaffold-eth/tree/master/packages/react-app/src/components"
            target="_blank"
            rel="noopener noreferrer"
          >
            📦 components
          </a>
        </Card>

        <Card style={{ marginTop: 32 }}>
          <div>
            There are tons of generic components included from{" "}
            <a href="https://ant.design/components/overview/" target="_blank" rel="noopener noreferrer">
              🐜 ant.design
            </a>{" "}
            too!
          </div>

          <div style={{ marginTop: 8 }}>
            <Button type="primary">Buttons</Button>
          </div>

          <div style={{ marginTop: 8 }}>
            <SyncOutlined spin /> Icons
          </div>

          <div style={{ marginTop: 8 }}>
            Date Pickers?
            <div style={{ marginTop: 2 }}>
              <DatePicker onChange={() => {}} />
            </div>
          </div>

          <div style={{ marginTop: 32 }}>
            <Slider range defaultValue={[20, 50]} onChange={() => {}} />
          </div>

          <div style={{ marginTop: 32 }}>
            <Switch defaultChecked onChange={() => {}} />
          </div>

          <div style={{ marginTop: 32 }}>
            <Progress percent={50} status="active" />
          </div>

          <div style={{ marginTop: 32 }}>
            <Spin />
          </div>
        </Card>
      </div>
    </div>
  );
}
