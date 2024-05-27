// npx ts-node lesson-2/query-metadata.ts

import Query from "@irys/query";

(async () => {
  const author = "Y5uoswBP4BBJH_sfRTE9Z4AjnoIh6ZH62HGOhFUU9Zo";

  const myQuery = new Query({ network: "arweave" });
  const results = await myQuery
    .search("arweave:transactions")
    .tags([
      { name: "Content-Type", values: ["application/json"] },
      {
        name: "App-Name",
        values: ["ArweavePH-Cohort-0"],
      },
      {
        name: "Title",
        values: [
          "Lesson 2: Deep Dive into the Arweave Cookbook - Core Concepts",
        ],
      },
    ])
    .first();

  console.log("results ==>", results.id);
})();
