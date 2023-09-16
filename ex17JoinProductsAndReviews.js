const { MongoClient } = require('mongodb');

async function main() {
  const url = "mongodb://localhost:27017";
  const client = new MongoClient(url, { useUnifiedTopology: true });
  
  try {
    await client.connect();
    console.log('Connected successfully to server');

    const db = client.db('proiectDB');
    const productsCollection = db.collection('products');

    await productsCollection.updateMany({}, {
        $set: {REVIEWS: [] }
    }); //cream un nou array in care sa introducem review urile

    
    let products = await productsCollection.find().toArray();

    const reviewsCollection = db.collection('reviews');
    const reviews = await reviewsCollection.find().toArray();
    
    
    for(let review of reviews){ //ne uitam la fiecare review
        let pID = review.PRODUCT_ID; //ii salvam id ul produsului
        review.PRODUCT_ID = null; // ii golim valoarea
        delete review.PRODUCT_ID; //stergem obiectul din review pentru a l putea introduce in products fara product_ID
    
        await productsCollection.updateOne({PRODUCT_ID: pID}, {
                $push: {REVIEWS: review} //bagam review ul in array ul REVIEWS
            })
        
    }
    


    // await productsCollection.updateMany({}, { //aici avem pt a sterge pt a putea demonstra ca functioneaza
    //     $unset: {REVIEWS: ''}
    // })

  } catch (err) {
    console.log(err.stack);
  }
  
  client.close();
}



main().catch(console.error);
