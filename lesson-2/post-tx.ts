// npx ts-node lesson-2/post-tx.ts

// Import the dotenv package to load environment variables from a .env file
import "dotenv/config";

// Import the TurboFactory from the @ardrive/turbo-sdk package
import { ArweaveSigner, TurboFactory } from "@ardrive/turbo-sdk";

// Import the  createData functions from the arbundles package
import { createData } from "arbundles";

// Import the fs module to work with the file system
import fs from "fs";

(async () => {
  // Check if the PATH_TO_WALLET environment variable is set
  if (!process.env.PATH_TO_WALLET) {
    // If not, log an error message and exit the process
    console.error("Please set PATH_TO_WALLET in your env.");
    process.exit();
  }

  // Read the wallet file specified by the PATH_TO_WALLET environment variable and parse it as JSON
  const JWK = JSON.parse(
    fs.readFileSync(process.env.PATH_TO_WALLET).toString()
  );

  // Create an authenticated Turbo instance using the private key from the wallet
  const turbo = TurboFactory.authenticated({ privateKey: JWK });

  // Create a new ArweaveSigner instance using the wallet
  const signer = new ArweaveSigner(JWK);

  // Create a new data item to be signed
  const signedDataItem = createData(
    // The data to be signed is a JSON string
    JSON.stringify({
      title: "Lesson 2: Deep Dive into the Arweave Cookbook - Core Concepts",
      content: "This lesson covers the core concepts of the Arweave Cookbook.",
    }),
    // The signer to be used to sign the data
    signer,
    {
      tags: [
        { name: "Content-Type", value: "application/json" },
        { name: "App-Name", value: "ArweavePH-Cohort-0" },
        { name: "App-Version", value: "0.1.0" },
        {
          name: "Title",
          value:
            "Lesson 2: Deep Dive into the Arweave Cookbook - Core Concepts",
        },
        {
          name: "Author",
          value: "Y5uoswBP4BBJH_sfRTE9Z4AjnoIh6ZH62HGOhFUU9Zo",
        },
      ],
    }
  );

  // Sign the data item
  await signedDataItem.sign(signer);

  // Upload the signed data item using the Turbo instance
  const uploadResult = await turbo.uploadSignedDataItem({
    // Provide a factory function to get the raw data item stream
    dataItemStreamFactory: () => signedDataItem.getRaw(),
    // Provide a factory function to get the size of the raw data item
    dataItemSizeFactory: () => signedDataItem.getRaw().length,
    // Optional: set a timeout to cancel the upload after 10 seconds
    signal: AbortSignal.timeout(10_000),
  });

  // Log the result of the upload
  console.log(JSON.stringify(uploadResult, null, 2));
})();
