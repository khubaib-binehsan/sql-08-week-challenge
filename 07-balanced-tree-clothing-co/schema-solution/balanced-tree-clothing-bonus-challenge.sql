SET search_path = balanced_tree;

-- e-BonusQuestion

-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

WITH cte AS (
	SELECT
		ph2.parent_id as category_id,
		ph1.parent_id as segment_id,
		ph1.id as style_id,
		ph3.level_text as category_name,
		ph2.level_text as segment_name,
		ph1.level_text as style_name
	FROM product_hierarchy ph1
	INNER JOIN product_hierarchy ph2 ON ph2.id = ph1.parent_id
	INNER JOIN product_hierarchy ph3 ON ph3.id = ph2.parent_id
	WHERE ph1.level_name = 'Style')
	
SELECT
	p.product_id,
	p.price,
	style_name || ' - ' || segment_name || ' - ' || category_name as product_name,
	category_id,
	segment_id,
	style_id,
	category_name::text,
	segment_name::text,
	style_name::text
FROM cte c
INNER JOIN product_prices p
	ON p.id = c.style_id
ORDER BY category_id, segment_id, style_id;