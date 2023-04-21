const AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var params = "";

exports.handler = async message => {
  console.log(message);
  
  if (message.body) {
    let bookmark = JSON.parse(message.body);
    if (bookmark.shared === true) {
       params = {
        TableName: process.env.TABLE_NAME,
        Item: {
          id: { S: bookmark.id },
          url: { S: bookmark.url },
          name: { S: bookmark.name },
          description: { S: bookmark.description },
          username: { S: bookmark.username },
          shared: { BOOL: false },
          contest: {S: "na"}
        }
      };
    console.log(`Adding bookmark to table ${process.env.TABLE_NAME}`);
    await dynamodb.putItem(params).promise();
    console.log(`New bookmark added to the inventory with shared flag as false`);
    
    params = {
        TableName: process.env.TABLE_NAME,
        Item: {
          id: { S: bookmark.id+"n" },
          url: { S: bookmark.url },
          name: { S: bookmark.name },
          description: { S: bookmark.description },
          username: { S: bookmark.username },
          shared: { BOOL: bookmark.shared },
          contest: {S: "Entering"}
        }
      };
    
    await dynamodb.putItem(params).promise();
    console.log(`New bookmark added to the inventory with shared flag as true`);
    }
    else
    {
      params = {
        TableName: process.env.TABLE_NAME,
        Item: {
          id: { S: bookmark.id },
          url: { S: bookmark.url },
          name: { S: bookmark.name },
          description: { S: bookmark.description },
          username: { S: bookmark.username },
          shared: { BOOL: false },
          contest: {S: "na"}
        }
      };
      console.log(`Adding bookmark to table ${process.env.TABLE_NAME}`);
      await dynamodb.putItem(params).promise();
      console.log(`New bookmark added to the inventory`);
    }
  }
  return {
    statusCode: 200,
    headers: {"Access-Control-Allow-Origin": '*'},
    body: JSON.stringify({})
  };
};
