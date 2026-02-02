import { onchainTable } from "ponder";

export const property = onchainTable("property", (t) => ({
  id: t.integer().primaryKey(),
  owner: t.text().notNull(),
  price: t.bigint().notNull(),
  forSale: t.boolean().notNull(),
  location: t.text().notNull(),
  locationHash: t.text().notNull(),
  listedAt: t.bigint().notNull(),
  soldAt: t.bigint(),
}));

export const offer = onchainTable("offer", (t) => ({
  id: t.text().primaryKey(),
  propertyId: t.integer().notNull(),
  buyer: t.text().notNull(),
  amount: t.bigint().notNull(),
  active: t.boolean().notNull(),
  createdAt: t.bigint().notNull(),
}));

export const transaction = onchainTable("transaction", (t) => ({
  id: t.text().primaryKey(),
  propertyId: t.integer().notNull(),
  seller: t.text().notNull(),
  buyer: t.text().notNull(),
  price: t.bigint().notNull(),
  timestamp: t.bigint().notNull(),
}));

export const profile = onchainTable("profile", (t) => ({
  address: t.text().primaryKey(),
  name: t.text(),
  bio: t.text(),
  avatarUrl: t.text(),
  updatedAt: t.bigint().notNull(),
}));
