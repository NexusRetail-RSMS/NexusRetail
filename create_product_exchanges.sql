-- Migration: Create Product Exchanges Table

CREATE TABLE product_exchanges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_order_id UUID REFERENCES orders(id),
    original_product_id UUID NOT NULL,
    replacement_product_id UUID NOT NULL,
    amount_paid DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'completed',
    store_id UUID REFERENCES stores(id),
    associate_id UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE product_exchanges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow associates to insert exchanges"
    ON product_exchanges FOR INSERT
    WITH CHECK (auth.uid() = associate_id);

CREATE POLICY "Allow all authenticated users to read exchanges"
    ON product_exchanges FOR SELECT
    USING (auth.role() = 'authenticated');
