import React, {useState} from 'react';
import {Route} from 'react-router-dom';
import {Container, Row, Col, FormControl, Alert, Button, Spinner} from 'react-bootstrap';
import {withContext} from '../../1_context';
import './index.css';


function InitializeContract(props) {
    const [farmerID, setFarmerID] = useState(null);
    const [distributorID, setDistributorID] = useState(null);
    const [retailerID, setRetailerID] = useState(null);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState(false);
    const [address, setAddress] = useState(null);
    const [submitting, setSubmitting] = useState(false);
    const [gas, setGas] = useState(null);
    const [gasPrice, setGasPrice] = useState(null);
    
    const onSubmit = async () => {
        setSubmitting(true);
        setSuccess(false);
        setError(false);
        setAddress(null);
        try {
            const supplyChainContract = await new props.web3.eth.Contract(props.abi);
            supplyChainContract.deploy({
                arguments: [farmerID, distributorID, retailerID],
                data: props.bytecode
            })
            .send({
                from: props.account,
                gas: gas === null ? 5000000 : gas,
                gasPrice: gasPrice === null ? '90000000000' : gasPrice
            })
            .then(newContractInstance => {
                props.actions.setDeployedAddress(newContractInstance.options.address);
                setAddress(newContractInstance.options.address);
                setSuccess(true);
                setSubmitting(false);
            });
        } catch(error) {
            setError(true);
            setSubmitting(false);
            console.log({error});
        }
    }

    return (
        <Route exact path={'/init'}>
            <Container>
                <Row>
                    <Col xs={4}>
                    <section className={'abi-label'}>
                        <center>
                            <code>
                                Base Supply Chain ABI Code
                            </code>
                        </center>
                    </section>
                    <section className={'abi-container'}>
                        <pre>
                            {JSON.stringify(props.abi, null, 2)}
                        </pre>
                    </section>
                    </Col>
                    <Col xs={8}>
                        <section className={'initialize-contract-label'}>
                            <center>
                                <code>
                                    Deploy a Supply Chain Contract
                                </code>
                            </center>
                        </section>
                        <section className={'initialize-contract-container'}>
                            <br/>
                            <Alert variant={'primary'}>
                                <Alert.Heading>Deploying a Contract</Alert.Heading>
                                <hr/>
                                    To deploy a supply chain contract, <u>you will need to access this page
                                    from the address intended to be the owner of the instance
                                    of the supply chain contract</u>. The owner cannot be the farmer, distributor,
                                    or retailer. 
                                    <br/><br/>
                                    The supply chain contract must be initialized with one farmer, one distributor,
                                    and one retailer. <u>If the default gas and gas price values do not seem to work, adjust them. 
                                    Otherwise, it is best not to touch those fields.</u>
                                    <br/><br/>
                                    The owner of this contract will be able to add farmers, distributors, and retailers
                                    to the smart contract instance, whom in turn may also participate in the deployed supply chain.
                                    <br/><br/>
                                    Below, the roles of participants in the supply chain are explained.
                                    <br/><br/>
                                    <h5>Owner</h5>
                                    <hr/>
                                    Actions an owner may take as a nondirect participant of the deployed supply chain contract are: &nbsp;
                                    <code>adding a farmer</code>,&nbsp;
                                    <code>adding a distributor</code>,&nbsp;
                                    <code>adding a retailer</code>,&nbsp;
                                    and <code>killing the contract</code>.
                                    <br/><br/>
                                    <h5>Farmer</h5>
                                    <hr/>
                                    A farmer has access the ability to harvest a product, 
                                    kicing off the lifecycle of a product by assigning it the following attributes:
                                    <code>originFarmName</code>,&nbsp;
                                    <code>originFarmInformation</code>,&nbsp;
                                    <code>originFarmLatitude</code>,<br/>
                                     <code>originFarmLongitude</code>,&nbsp;
                                    and <code>productName</code>.
                                    <br/><br/>
                                    Actions a farmer may take as a participant in the supply chain are: &nbsp;
                                    <code>harvesting</code>,&nbsp; 
                                    <code>processing</code>,&nbsp;
                                    <code>packing</code>,&nbsp;
                                    and <code>adding to a palette</code>. By adding a product to a palette,
                                    the farmer is indicating the product's ability to be purchased by a distributor.
                                    <br/><br/>
                                    <h5>Distributor</h5>
                                    <hr/>
                                    Actions a distributor may take as a participant in the supply chain are:<br/>
                                    <code>buying a palette</code> and <code>shipping a palette to a retailer</code>.
                                    <br/><br/>
                                    <h5>Retailer</h5>
                                    <hr/>
                                    Actions a retailer may take as a participant in the supply chain are: <br/>
                                    <code>receiving a palette</code> and <code>intializing a sale to a consumer</code>.
                                    Retailers have the sole ability to grant the role of Consumer in the supply chain as an intermediary
                                    automated step in initializing a sale.
                                    <br/><br/>
                                    <h5>Consumer</h5>
                                    <hr/>
                                    A consumer is a unique role that can only be granted by a retailer on prompt of sale.
                                    The only action a consumer may take as a participant in the supply chain is <code>buying a product</code>.
                                <hr />
                                <p className="mb-0">
                                    <i>
                                        You must have access to the addresses provided for the farmer, distributor, and retailer
                                        to interact with the contract's role based actions.
                                    </i>
                                </p>
                            </Alert>
                            <br/>
                            {
                                error === true && success === false && 
                                <Alert variant={'danger'}>
                                    Error encountered. Check console for details.
                                </Alert>
                            }
                            {
                                success === true ? (
                                <Alert variant={'success'}>
                                    <span>Contract was successfully deployed at address: <b>{address}</b></span>
                                    <br/><br/>
                                    <Alert.Link href="#" onClick={() => window.localStorage.setItem('address', address)}>
                                        <i class="far fa-save"></i> Save Address to Local Storage for app usage
                                    </Alert.Link>
                                </Alert>) : ''
                            }
                            <FormControl 
                                placeholder={'Enter originFarmerID (initialFarmer)'} 
                                onChange={e => setFarmerID(e.target.value)}
                            />
                            <br/>
                            <FormControl 
                                placeholder={'Enter distributorID (initialDistributor)'}
                                onChange={e => setDistributorID(e.target.value)}
                            />
                            <br/>
                            <FormControl 
                                placeholder={'Enter retailerID (initialRetailer)'}
                                onChange={e => setRetailerID(e.target.value)}
                            />
                            <br/>
                            <hr/>
                            <FormControl 
                                placeholder={'**Optional** Gas (default 5000000)'}
                                onChange={e => setGas(Number(e.target.value))}
                            />
                            <br/>
                            <FormControl 
                                placeholder={'**Optional** Gas Price (default 90000000000)'}
                                onChange={e => setGasPrice(e.target.value)}
                            />
                            <br /><br/>
                            <section className={'initialize-contract-button'}>
                                <center>
                                    <Button disabled={submitting} onClick={() => onSubmit()}>
                                        {submitting ? 
                                            <Spinner animation="border" variant="light" /> :
                                            <span><i class="fas fa-file-export"></i> Deploy Contract</span>
                                        }
                                    </Button>
                                </center>
                            </section>
                        </section>
                    </Col>
                </Row>
            </Container>
        </Route>
    )
}

export default withContext(InitializeContract);