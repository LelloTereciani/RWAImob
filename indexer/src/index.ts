import { and, eq } from "drizzle-orm";
import { ponder } from "ponder:registry";
import { property, offer, transaction } from "ponder:schema";

ponder.on("PropertySale:PropertyListed", async ({ event, context }: any) => {
    const { propertyId, seller, price, location, locationHash } = event.args;

    await context.db.insert(property).values({
        id: Number(propertyId),
        owner: seller,
        price: price,
        forSale: true,
        location: location,
        locationHash: locationHash,
        listedAt: event.block.timestamp,
    }).onConflictDoUpdate({
        price: price,
        forSale: true,
        listedAt: event.block.timestamp,
        owner: seller,
        location: location,
        locationHash: locationHash,
    });
});

ponder.on("PropertySale:PropertySold", async ({ event, context }: any) => {
    const { propertyId, seller, buyer, price } = event.args;

    await context.db.update(property, { id: Number(propertyId) }).set({
        owner: buyer,
        forSale: false,
        soldAt: event.block.timestamp,
    });

    await context.db.insert(transaction).values({
        id: `${event.transaction.hash}-${event.log.logIndex}`,
        propertyId: Number(propertyId),
        seller: seller,
        buyer: buyer,
        price: price,
        timestamp: event.block.timestamp,
    });
});

ponder.on("PropertySale:OfferMade", async ({ event, context }: any) => {
    const { propertyId, buyer, amount } = event.args;

    await context.db.insert(offer).values({
        id: `${event.transaction.hash}-${event.log.logIndex}`,
        propertyId: Number(propertyId),
        buyer: buyer,
        amount: amount,
        active: true,
        createdAt: event.block.timestamp,
    });
});

ponder.on("PropertySale:OfferWithdrawn", async ({ event, context }: any) => {
    const { propertyId, buyer, amount } = event.args;

    const activeOffers = await context.db.sql
        .select()
        .from(offer)
        .where(
            and(
                eq(offer.propertyId, Number(propertyId)),
                eq(offer.buyer, buyer),
                eq(offer.amount, amount),
                eq(offer.active, true)
            )
        );

    // Desativamos a primeira encontrada (ou todas, se houver duplicatas no cache/estado)
    for (const off of activeOffers) {
        await context.db.update(offer, { id: off.id }).set({
            active: false
        });
    }
});

ponder.on("PropertySale:PropertyStatusChanged", async ({ event, context }: any) => {
    const { propertyId, newStatus } = event.args;

    await context.db.update(property, { id: Number(propertyId) }).set({
        forSale: newStatus,
    });
});

ponder.on("PropertySale:PropertyPriceUpdated", async ({ event, context }: any) => {
    const { propertyId, newPrice } = event.args;

    await context.db.update(property, { id: Number(propertyId) }).set({
        price: newPrice,
    });
});
