import { SyncOutlined } from "@ant-design/icons";
import { utils } from "ethers";
import { Button, Card, Collapse, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { Address, Balance } from "../components";

// const fruitTreePng = require('../lpc-fruit-trees/fruit-trees.png');
import fruitTreePng from '../lpc-fruit-trees/fruit-trees.png';
import iconWater from '../foundicons/water.png';
import iconFire from '../foundicons/fire.png';
import iconBeaker from '../foundicons/beaker.png';
import iconScythe from '../foundicons/scythe.png';

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

const { Panel } = Collapse;

const TreeStages = ['SEED', 'SPROUT', 'BABY', 'TEENAGE', 'ADULT', 'DEAD']
const MassPerStage = 50; // make same as in Seed.sol

function mass2stage(m) {
  if (false) {
    // TODO
    return 'DEAD';
  }
  if (m < 100) {
    return 'SEED';
  }
  return TreeStages[Math.min(4, Math.floor(m / MassPerStage))];
}
const SpeciesNames = ['Lingo', 'Mican', 'Nasu', 'Abo', 'Cheri', 'Ume', 'Nana', 'Coco'];
function species2name(speciesIdx) {
  return SpeciesNames[speciesIdx];
}

const MAX_UINT16 = 65535;
const MAX_UINT256 = '115792089237316195423570985008687907853269984665640564039457584007913129639935';
const FRUIT_PER_MASS = 10;

//export default
function TreeCardIdx({
  idx,
  address,
  mainnetProvider,
  localProvider,
  tx,
  readContracts,
  writeContracts,
}) {
  const seedIdObj = useContractReader(readContracts, "Seed", "tokenOfOwnerByIndex", [address, idx]);

  return seedIdObj ? (<TreeCardInner
              seedId={seedIdObj.toNumber()}
              address={address}
              readContracts={readContracts}
              writeContracts={writeContracts}
              tx={tx}
           />) : '';
}
function TreeCardInner({
  seedId,
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
  // returns (uint8 species, uint8 growthFactor, uint8 waterUseFactor, uint8 fertilizerUseFactor, uint8 fruitGrowthFactor) 
  const treeTraits = useContractReader(readContracts, "Seed", "traits", [seedId]);
  const treeState = useContractReader(readContracts, "Seed", "state", [seedId]);
  console.log('state: ', treeState);
  const landId = useContractReader(readContracts, "Seed", "landId", [seedId]);
  const species = treeTraits ? treeTraits[0] : null;
  const speciesName = species === null ? '_ERROR_' : species2name(species);
  console.log('species: ', speciesName)
  const posX = SpeciesBabyImgOffsets[speciesName][0] * 96;
  const stageOffY = (treeState - 1) * 128; // only applicable if not SEED and DEAD
  const posY = SpeciesBabyImgOffsets[speciesName][1] * 128 - stageOffY;
  const deadStyle = {objectFit: 'none', objectPosition: '0 -896px', width: 96, height: 128, position: 'absolute', top: -64};
  const treeStyle = treeState ? (TreeStages[treeState] == 'DEAD' ? deadStyle :
                                 {objectFit: 'none', objectPosition: `-${posX}px -${posY}px`, width: 96, height: 128, position: 'absolute', top: -64}) : {};
  const mass = useContractReader(readContracts, "Seed", "mass", [seedId]);
  const waterLevel = useContractReader(readContracts, "Seed", "waterLevel", [seedId]);
  const fruitMass = useContractReader(readContracts, "Seed", "fruitMass", [seedId]);
  const fruitCount = Math.floor((fruitMass ? fruitMass.toNumber() : 0) / FRUIT_PER_MASS);

  return (
    <Card>
          <div style={{marginTop: 100, position: 'relative'}}>
            { !treeState ? '' : (<img src={fruitTreePng} style={treeStyle} />) }
            <span className="gnd gnd-tilled-in-grass"><span id={"tree-1-" + seedId}></span></span>
          </div>
          <h3>Stats</h3>
          <div> ID: { seedId }</div>
          <div> Species: { speciesName }</div>
          <div> Traits/Factors: { treeTraits ? treeTraits.join(', ') : '' }</div>
          { landId === MAX_UINT16 ?
             (<div> Land: Unplanted </div>) : 
             (<div> Land X/Y: { landId % 32 } / { Math.floor(landId / 32) }</div>)
          }
          <div> Mass: { mass ? mass.toNumber() : 0 }</div>
          <div> Water Level: { waterLevel ? waterLevel.toString() : 'N/A' } </div>
          <div> Stage from mass: { mass2stage(mass ? mass.toNumber() : 0) }</div>
          <div> treeState: { TreeStages[treeState] }</div>

          <div> Fruit: { fruitCount } </div>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.water(seedId), update => {
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
              Water! <img src={iconWater} width='20' />
          </Button>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Currency.approve(readContracts.Seed.address, utils.parseEther('12345')), update => {
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
              Approve before fertilize !
          </Button>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.fertilize(seedId), update => {
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
              Fertilize !  <img src={iconBeaker} width='20' />
          </Button>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.harvest(seedId), update => {
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
              Harvest !
              <img src={iconScythe} width='20' />
          </Button>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.burn(seedId), update => {
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
              Burn ! <img src={iconFire} width='20' />
          </Button>
          <Divider />
    </Card>
  );
}

function TreeBuilder({
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  tx,
  readContracts,
  writeContracts,
}) {
  const [newCurrencyApproveAmount, setNewCurrencyApproveAmount] = useState(utils.parseUnits('0.1').toString());
  const currencyBalance = useContractReader(readContracts, "Currency", "balanceOf", [address]);
  const fruitPrice = useContractReader(readContracts, "Fruit", "price");
  const fruitBalance = useContractReader(readContracts, "Fruit", "balanceOf", [address]);
  const [newFruitApproveAmount, setNewFruitApproveAmount] = useState(utils.parseUnits('100').toString());
  const [newFruitBuyAmount, setNewFruitBuyAmount] = useState("1");
  const seedBalance = useContractReader(readContracts, "Seed", "balanceOf", [address]);
  const landPrice = useContractReader(readContracts, "Land", "price");
  const [newLandId, setNewLandId] = useState("0");
  const [newSeedId, setNewSeedId] = useState("0");
  const firstSeedId = useContractReader(readContracts, "Seed", "tokenOfOwnerByIndex", [address, 0]);
  const firstLandId = useContractReader(readContracts, "Land", "tokenOfOwnerByIndex", [address, 0]);
  const landBalance = useContractReader(readContracts, "Land", "balanceOf", [address]);
  return (
    <Collapse><Panel header="Tree Builder" >
      <h2>Steps to Make a Tree</h2>
      <ol>
        <li>
          <h3>Mint yourself free Currency</h3>
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Currency.mint(utils.parseUnits('1')), update => {
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
              Give me free money!
          </Button>
        </li>
        <li>
        <h3>Approve Currency for Fruit</h3>
          Your Currency balance: { currencyBalance ? `${currencyBalance.toString()} (${utils.formatEther(currencyBalance)})` : '...' }
          <Input
            onChange={e => {
              setNewCurrencyApproveAmount(e.target.value);
            }}
            value={newCurrencyApproveAmount}
          />
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Currency.approve(readContracts.Fruit.address, newCurrencyApproveAmount), update => {
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
              Approve Currency for Fruit!
          </Button>
        </li>
        <li>
        <h3>Buy Fruit </h3>
          <div>Fruit price in currency: { fruitPrice ? fruitPrice.toString() : '...' }</div>
          <div>Amount to buy</div>
          <Input
            onChange={e => {
              setNewFruitBuyAmount(e.target.value);
            }}
            value={newFruitBuyAmount}
          />
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Fruit.buy(utils.parseUnits(newFruitBuyAmount)), update => {
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
              Buy Fruits!
          </Button>
        </li>
        <li>
        <h3>Approve Fruit for Seed</h3>
          Your Fruit balance: { fruitBalance ? `${fruitBalance.toString()} (${utils.formatEther(fruitBalance)})` : '...' }
          <Input
            onChange={e => {
              setNewFruitApproveAmount(e.target.value);
            }}
            value={newFruitApproveAmount}
          />
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Fruit.approve(readContracts.Seed.address, newFruitApproveAmount), update => {
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
              Approve Fruit for Seed
          </Button>
        </li>
        <li>
        <h3>Buy Seed </h3>
          <div>Seed price hard-coded at <Input disabled={true} value='10**17' /></div>
          <div>Amount to buy</div>
          <Input
            disabled={true}
            value={1}
          />
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.buy(), update => {
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
              Buy 1 Seed!
          </Button>
          <div>Your Seed balance: { seedBalance ? seedBalance.toString() : '...' }</div>
        </li>
        <li>
        <h3>Approve Currency for Land</h3>
          Your Currency balance: { currencyBalance ? `${currencyBalance.toString()} (${utils.formatEther(currencyBalance)})` : '...' }
          <Input
            onChange={e => {
              setNewCurrencyApproveAmount(e.target.value);
            }}
            value={newCurrencyApproveAmount}
          /> (duplicated above)
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Currency.approve(readContracts.Land.address, newCurrencyApproveAmount), update => {
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
              Approve Currency for Land!
          </Button>
        </li>
        <li>
        <h3>Buy Land </h3>
          <div>Current Land price: { landPrice ? landPrice.toString() + ' = ' + utils.formatEther(landPrice) : '...' }</div>
          <div>Land ID you want to buy</div>
          <Input
            onChange={e => {
              setNewLandId(e.target.value);
            }}
            value={newLandId}
          />
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Land.buy(parseInt(newLandId)), update => {
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
              Buy that Land!
          </Button>
          <div>Your Land balance: { landBalance ? landBalance.toString() : '...' }</div>
        </li>
        <li>
        <h3>Plant a Seed on a Land </h3>
          <div>Your Seed balance: { seedBalance ? seedBalance.toString() : '...' }</div>
          <div>Your first SeedId if you have one: { firstSeedId ? firstSeedId.toString() : '' }</div>
          <div>Your first LandId if you have one: { firstLandId ? firstLandId.toString() : '' }</div>
          <div>Seed ID you want to plant </div>
          <Input
            onChange={e => {
              setNewSeedId(e.target.value);
            }}
            value={newSeedId}
          />
          <div>Land ID you want to plant seed on</div>
          <Input
            onChange={e => {
              setNewLandId(e.target.value);
            }}
            value={newLandId}
          />
          <Button
            style={{ marginTop: 8 }}
            onClick={async () => {
              const result = tx(writeContracts.Seed.plant(parseInt(newSeedId), parseInt(newLandId)), update => {
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
              Plant Seed on Land!
          </Button>
        </li>
      </ol>
      
    </Panel></Collapse>
  )
}
function fakeGameState(gameState) {
  if (!gameState) return null;
  console.log(gameState[0]);
  return gameState.map(data => {
    let newData = { ...data };
    newData.seedSpecies = Math.floor(Math.random() * 8);
    newData.seedId = gameState[0].seedId;
    newData.seedState = /*Math.random() < 0.2 ? 3 : 4; //*/ Math.floor((Math.random() < 0.1 ? 0 : 1) + Math.random() * 4);
    // TODO display .landType somehow
    // TODO unharvestedFruits.toNumber()
    newData.fakeFruits = newData.seedState != 4 ? 0 : Math.floor(Math.random() * 10); // TODO what's a reasonable count range
    newData.fakeFruits += 1;
    newData.fakeFruitColor = Math.floor(Math.random() * 4);
    return newData;
  });
}
function TreeMap2({
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  tx,
  readContracts,
  writeContracts,
}) {
  const gameState = fakeGameState(useContractReader(readContracts, "Seed", "gameState"));
  console.log('............................. game state ', gameState);
  const stateRowCount = gameState ? Math.floor(gameState.length / 32) : 0;
  const stateRowsIndexes = [...Array(stateRowCount).keys()];
  const stateRows = gameState ? stateRowsIndexes.map(rowIdx => gameState.slice(32*rowIdx, 32*(1+rowIdx))) : [];

  return (
    <Collapse><Panel header="Tree Map" >
      <div style={{overflow: 'scroll scroll', height: 600, paddingTop: 100}}>
        { gameState ? stateRowsIndexes.map(rowIdx => (<TreeMapRow key={'treemaprow-'+rowIdx}
                gameStateRow={stateRows[rowIdx]}
                rowIdx={rowIdx}
            />)) : '' }
      </div>
    </Panel></Collapse>
  )
}
const SpeciesBabyImgOffsets = { 
    // [x * 96, y * 128]
    'Lingo': [0, 3],
    'Mican': [1, 3],
    'Nasu':  [4, 3],
    'Abo':   [6, 3],
    'Cheri': [3, 3],
    'Ume':   [7, 3],
    'Nana':[1, 11],
    'Coco':  [0, 11],
    '_ERROR_': [0, 0],
};
const FruitRow1 = 16; // row of apple tree
// points to smallest fruit, first color
const SpeciesFruitImgOffsets = {
    'Lingo': [0, 2 + FruitRow1],
    'Mican': [5, 2 + FruitRow1],
    'Nasu':  [3, 5 + FruitRow1],
    'Abo':   [7, 5 + FruitRow1],
    'Cheri': [2, 5 + FruitRow1],
    'Ume':   [8, 5 + FruitRow1],
    'Nana':  [3, 8 + FruitRow1],
    'Coco':  [2, 8 + FruitRow1],
    '_ERROR_': [0, 0],
};
function calcTreePos(species, treeState, fruitCount) {
    // XXX quick hack, all dead trees look the same
    if (TreeStages[treeState] == 'DEAD') { 
      return '0 -896px';
    }
    if (TreeStages[treeState] == 'ADULT' && fruitCount > 0) {
      const offs = SpeciesFruitImgOffsets[species2name(species)];
      const fruitOff = fruitCount > 20 ? 2 : Math.floor(fruitCount / 10);
      return `-${offs[0] * 96}px -${(offs[1] - fruitOff) * 128}px`;
    }
    const posX = SpeciesBabyImgOffsets[species2name(species)][0] * 96;
    const stageOffY = (treeState - 1) * 128; // only applicable if not SEED and DEAD
    const posY = SpeciesBabyImgOffsets[species2name(species)][1] * 128 - stageOffY;
    return `-${posX}px -${posY}px`;
}
function TreeMapRow({
  gameStateRow,
  rowIdx,
}) {
 // return (<div>{rowIdx} {gameStateRow.length}</div>);
  const getTreeStyle = (species, treeState, fruitCount) => {
    return {objectFit: 'none', objectPosition: calcTreePos(species, treeState, fruitCount), width: 96, height: 128, position: 'absolute', top: -64};
  };
  const normalSeedId = (seedIdObj) => seedIdObj ? (seedIdObj.toString() == MAX_UINT256 ? null : seedIdObj.toNumber()) : null;
  return (
    <div style={{width:3200, height:94 /* XXX */}} >
      { gameStateRow.map((data, colIdx) =>
          (<div key={`foo-${rowIdx}-${colIdx}`} style={{display:'inline-block', /*border: '1px solid black', width:100, height: 100,*/ position: 'relative'}}>
            { (!data.seedState || normalSeedId(data.seedId) === null) ? '' : (<img src={fruitTreePng} style={getTreeStyle(data.seedSpecies, data.seedState, data.fakeFruits)} />) }
            <span className="gnd gnd-tilled-in-grass">{/*<span id={"tree-" + (data.seedId }></span>*/}</span>
            <div style={{position: 'absolute', top: 0, left: 0, opacity: 0.5}}>
              <div>id { normalSeedId(data.seedId)}</div>
              <div>species { data.seedSpecies.toString() }</div>
              <div>state { data.seedState.toString() }</div>
            </div>
           </div>))
       }
    </div>
  )
}
function LandInfoInner({
  landId,
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  tx,
  readContracts,
  writeContracts,
}) {
  const landType = useContractReader(readContracts, "Land", "landTypes", [landId]);
  console.log('landType ', landType);
  const seedId = useContractReader(readContracts, "Seed", "seedByLandId", [landId]);
  if (seedId) console.log('seed ', seedId.toString());
  const noSeed = seedId ? seedId.toString() == MAX_UINT256 : true;

  return (
    <Card>
      <div>Land ID: { landId ? landId.toString() : '...' }</div>
      <div>Type: { landType !== undefined ? landType.toString() : '...' }</div>
      <div>Seed ID: { noSeed ? 'No seed' : (seedId ? seedId.toString() : '...') }</div>
    </Card>
  )
}
function LandInfo({
  landIdx,
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  tx,
  readContracts,
  writeContracts,
}) {
  const landId = useContractReader(readContracts, "Land", "tokenOfOwnerByIndex", [address, landIdx]);
  return landId ? (<LandInfoInner 
                      landId={landId.toNumber()}
                      address={address}
                      readContracts={readContracts}
                      writeContracts={writeContracts}
                      tx={tx}
    />) : '';
}
function LandRegistry({
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  tx,
  readContracts,
  writeContracts,
}) {
  const landBalance = useContractReader(readContracts, "Land", "balanceOf", [address]);
  const landIndexes = [...Array(landBalance ? landBalance.toNumber() : 0).keys()];

  return (
    <Collapse><Panel header="Your Land Registry" >
      <div>Land plots: { landBalance? landBalance.toString() : '...' }</div>
      <div>
        { landIndexes.map(landIdx =>
            <LandInfo key={'land-'+landIdx}
                landIdx={landIdx}
                address={address}
                readContracts={readContracts}
                writeContracts={writeContracts}
                tx={tx}
            />
          )
        }
      </div>
    </Panel></Collapse>
  )
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
        <TreeBuilder 
              address={address}
              mainnetProvider={mainnetProvider}
              localProvider={localProvider}
              yourLocalBalance={yourLocalBalance}
              tx={tx}
              writeContracts={writeContracts}
              readContracts={readContracts}
        />
        <Divider />
        <TreeMap2
              address={address}
              mainnetProvider={mainnetProvider}
              localProvider={localProvider}
              yourLocalBalance={yourLocalBalance}
              tx={tx}
              writeContracts={writeContracts}
              readContracts={readContracts}
        />
        <Divider />
        <LandRegistry
              address={address}
              mainnetProvider={mainnetProvider}
              localProvider={localProvider}
              yourLocalBalance={yourLocalBalance}
              tx={tx}
              writeContracts={writeContracts}
              readContracts={readContracts}
        />
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
            seedTokensOfOwnerByIndex.map(idx => <TreeCardIdx key={'treecard-'+idx}
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
      </div>
    </div>
  );
}
