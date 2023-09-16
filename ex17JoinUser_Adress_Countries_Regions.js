const { MongoClient } = require('mongodb');

async function main() {
  const url = "mongodb://localhost:27017";
  const client = new MongoClient(url, { useUnifiedTopology: true });
  
  try {
    await client.connect();
    console.log('Connected successfully to server');

    const db = client.db('proiectDB');
    const countriesCollection = db.collection('countries');
    const regionsCollection = db.collection('regions');
    const userAddressCollection = db.collection('user_address');

    const countries = await countriesCollection.find().toArray();
    const regions = await regionsCollection.find().toArray();
    const userAddress = await userAddressCollection.find().toArray();

    for(let region of regions){
        await countriesCollection.updateMany({REGION_ID: region.REGION_ID}, {
            $set: {REGION: region.NAME}
        })
    }

    await countriesCollection.updateMany({}, {
        $unset: {REGION_ID: ''}
    })
    
    for(let country of countries){
        await userAddressCollection.updateMany({COUNTRY_ID: country.COUNTRY_ID}, {
            $set: {COUNTRY: country.NAME,
                    REGION: country.REGION}
        })
    }

    await userAddressCollection.updateMany({}, { 
             $unset: {COUNTRY_ID: ''}
    })



  } catch (err) {
    console.log(err.stack);
  }
  
  client.close();
}



main().catch(console.error);
