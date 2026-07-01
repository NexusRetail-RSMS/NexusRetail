-- Seed inventory for Delhi store
INSERT INTO inventory_item (id, store_id, product_id, current_stock, reorder_level)
SELECT gen_random_uuid(), '2a00a868-5a25-428f-98da-ec34f3be7a86', item_id, floor(random() * 50 + 10)::int, 15
FROM products
WHERE category IN ('Tops', 'Bottoms', 'Outerwear', 'Dresses')
LIMIT 10;
