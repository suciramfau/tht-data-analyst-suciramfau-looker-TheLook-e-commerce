------------------------------------------
---- DATA PREPARATION AND CLEANING (SQL)
------------------------------------------

---------------------------------------------------------------------------------------
-- 1) Profiling: pengecekan ukuran table dan pengecekan duplikasi Primary Key (PK)
------- tujuan: untuk memastikan tidak ada duplikasi pada PK yang merusak join nantinya
---------------------------------------------------------------------------------------

----- 1. pengecekan row count pada setiap table
select 'users' as table_name, count(*) as n from users
union all select 'orders', count(*) from orders 
union all select 'order_items', count(*) from order_items 
union all select 'products', count(*) from products
union all select 'inventory_items', count(*) from inventory_items 
union all select 'events', count(*) from events 
union all select 'distribution_centers', count(*) from distribution_centers;

--- notes: union all digunakan untuk mendapatkan hasil dari select sehingga dapat digabungkan menjadi satu output table
--- hasil pengecekan
---- a. events 					= 2.431.963
---- b. inventory_items 		=   490.705, notes: wajar lebih besar dari products karena 1 product bisa memiliki banyak unit stock
---- c. order_items				=   181.759, notes: wajar lebih besar dari order, karena 1 order bisa lebih dari 1 items
---- d. users					=   100.000 
---- e. orders					=   125.226
---- f. products				=    29.120
---- f. distribution_centers	=        10, notes: jumlah gudang

----- 2. check duplikasi PK
select 'users' as table_name, count(*) - count(distinct id) as dup_pk from users 
union all select 'orders', count(*) - count(distinct order_id) from orders 
union all select 'order_items', count(*) - count(distinct id) from order_items 
union all select 'products', count(*) - count(distinct id) from products 
union all select 'inventory_items', count(*) - count(distinct id) from inventory_items
union all select 'events', count(*) - count(distinct id) from events 
union all select 'distribution_centers', count(*)-count(distinct id) from distribution_centers;

--- notes: union all digunakan untuk mendapatkan hasil dari select sehingga dapat digabungkan menjadi satu output table
--- formula:
	--- contoh count (*) - count (distict PK)
	--- kalau nilai PK unik maka hasil nya adalah total baris = jumlah nilai unik -- selisihnya 0
		---- kalau ada duplicate PK dapat dilihat dari adanya selisih nilai -- selisihnya x 0
--- hasil pengecekan:
	--- Tidak ada duplicate PK


---------------------------------------------------------------------------------------
-- 2) Orphan Records: Pengecekan Orphan Records untuk FK tidak punya parent
------- tujuan: untuk memastikan relasi ERD aman untuk dilakukan join
---------------------------------------------------------------------------------------

----- 1. order_items yang tidak punya order header
select count(*) as orphan_order_items
from order_items oi 
left join orders o on oi.order_id = o.order_id 
where o.order_id is null; --- hasil: 0 (tidak ada)

----- 2. order_items -> users
select count(*) as orphan_order_items_users
from order_items oi 
left join users u on oi.user_id = u.id 
where u.id is null; --- hasil: 0 (tidak ada)

----- 3. orders -> users
select count(*) as orphan_order_users
from orders o 
left join users u on o.user_id =u.id 
where u.id is null; --- hasil: 0 (tidak ada)

----- 4. order_items -> products
select count(*) as orphan_order_items_products
from order_items oi 
left join products p on oi.product_id = p.id 
where p.id is null; --- hasil: 0 (tidak ada)

----- 5. order_items -> inventory_items
select count(*) as orphan_order_items_inventory
from order_items oi 
left join inventory_items ii  on oi.inventory_item_id =ii.id 
where ii.id is null; --- hasil: 0 (tidak ada)

----- 6. inventory_items -> products
select count(*) as orphan_iventory_products
from inventory_items ii 
left join products p on ii.product_id = p.id 
where p.id is null; --- hasil: 0 (tidak ada)

----- 7. products -> distribution_centers
select count(*) as orphan_products_dc
from products p
left join distribution_centers dc on p.distribution_center_id =dc.id 
where dc.id is null; --- hasil: 0 (tidak ada)

----- 8. events -> users
select count(*) as orphan_events_users
from events e
left join users u on e.user_id=u.id 
where u.id is null;--- hasil: 1.125.671
		--- interpretasi:
			-- terdapat 1.125.671 baris di table events yang user_id nya tidak ditemukan di table users
			-- event tersebut tidak bisa dihubungkan ke user terdaftar
			-- Dalam bisnis hal ini merupakan hal yang wajar, kemungkinan dikarenakan:
				--- 1. user belum log in/belum daftar
				--- 2. pre-signup activity
				--- 3. bot/crawler/anonymous traffic
------ 8.1 pemisahan anonymous vs registered events 
select e.*,
	case 
		when u.id is null then 'anonymous'	
		else 'registered'
	end as user_type
from events e 
left join users u on e.user_id =u.id;

--------------------------------------------------
------ notes:
	--- Foreign Key validations revealed that all transactional tables are fully consistent. A large number of events
	---	records do not map to registred users, which is expected behavior as the events table captures both
	--- anonymous and registered user interactions. These records were intentionally excluded from sales 
	--- analysis and treated separated for behavioral analytics
	

---------------------------------------------------------------------------------------
-- 3) DATA QUALITY CHECKS
---------------------------------------------------------------------------------------	

----- 1. data quality checks - Timestamp Logic (orders)
--------- tujuan: menjamin analisis berbasis waktu (delivery duration, fulfillment performance) aman dan valid
select count(*) as invalid_orders_time_logic
from orders 
where (shipped_at is not null and created_at is not null and shipped_at < created_at)  
	or (delivered_at is not null and shipped_at is not null and delivered_at < shipped_at)
	or (returned_at is not null and created_at is not null and returned_at < created_at);
-------- result: 
--------------- invalid orders time logic = 112.696 dari total orders 125.226 
--------------- dengan kata lain kurang lebih 90% orders memiliki timestamps tidak konsisten
--------------- based on dataset information:
				-- * timestamp sering di generate terpisah
				-- * tidak dimaksudkan untuk analisis SLA logistik yang presisi
				-- * fokus dataset lebih ke sales & customer analytics
--------- best practice treatment:
			-- * created_at : untuk anchor time --- bisa digunakan untuk perhitungan durasi
			-- * is_shipped, is_delivered, is_returned : digunakan sebagai flag


----- 2. data quality checks - numeric validity (products)
--------- tujuan:untuk memastikan perhitungan revenue, cost, dan margin secara matematis dan bisnis aman
select
	count(*) filter (where cost <0) as negative_cost,
	count(*) filter (where retail_price <0) as negative_retail_price,
	count(*) filter (where retail_price = 0) as zero_retail_price
from products; 
-------- result: 
--------------- all negative values = 0, semua nilai bersifat valid

--------------------------------------------------
------ notes:
	--- Data quality checks revealed a significant number of timestamp inconsistencies in order fulfillment fields 
	--- (shipped, delivered, returned). This behavior is consistent with the synthetic nature of the dataset and 
	--- does not affect sales trend analysis. Therefore, created_at was used as the primary temporal reference, 
	--- while other timestamps were treated as status indicators. Numeric validation confirmed that all product 
	--- prices and costs are valid, ensuring reliable revenue and margin calculations.


---------------------------------------------------------------------------------------
-- 4) BUILD ANALYTICAL LAYER 
---------------------------------------------------------------------------------------	

----- 1. build analytical layer - dimensions views
--------- about dimension views:
		  -- table deskriptif yang akan menyimpan atribut/karakteristik dari entitas utama
		     -- co:
		     	 -- * user (gender, age, country, traffic_source)
			     -- * product (category, brand, departement, price)
				 -- * distribution center (lokasi gedung)
--------- tujuan/peruntukan: 
		  -- * menyediakan konteks untuk data transaksi
		  -- * menjadi lookup table saat analisis
		  -- * menjaga data tetap terstruktur dan konsisten
---------- pentingnya dimensi dalam analisa:
		  -- * memberikan insight lebih dalam analisa (WHO/WHAT/WHERE)
create or replace view dim_users as
select 
	id as user_id,
	first_name,
	last_name,
	email,
	age,
	case 
		when lower(coalesce(gender, '')) in ('m', 'male') then 'Male'
		when lower(coalesce(gender, '')) in ('f', 'female') then 'Female'
		when trim (coalesce(gender, '')) = '' then 'Unknown'
		else gender
	end as gender,
	city,
	state,
	country,
	postal_code,
	latitude,
	longitude,
	traffic_source,
	created_at as user_created_at
from users;

create or replace view dim_products as
select 
	id as product_id,
	name as product_name,
	brand as product_brand,
	category as product_category,
	department as product_department,
	sku as product_sku,
	cost::numeric as product_cost,
	retail_price::numeric as product_retail_price,
	distribution_center_id
from products;

create or replace view dim_distribution_centers as
select
	id as distribution_center_id,
	name as distribution_center_name,
	latitude as dc_latitude,
	longitude as dc_longitude
from distribution_centers;
	
----- 2. build analytical layer - fact view (order items)
--------- about fact views:
		  -- tabel transaksi inti, dimana dalam 1 baris merupakan 1 kejadian bisnis (co: 1 order items)
		     -- contain:
		  		-- * identifies	: order_id, user_id, product_id
		  		-- * timestamps	: order_created_at, item_delivered_at
		  		-- * measures	: quantity, revenue, cost, gross_margin
		  		-- * flags		: is_shipped, is_delivered, is_returned
--------- tujuan/peruntukan: 
		  -- * menjadi sumber kebenaran (source of truth) untuk metrik bisnis
		  -- * menyimpan angka yang akan dihitung dan diagregasi
--------- perbedaan fact vs dimension
		  -- * fact 		: terdiri dari banyak nilai/beberapa nilai 
		  -- * dimension	: penjelasan dari angka tersebut
---------- pentingnya dimensi dalam analisa:
		  -- * memberikan insight lebih dalam analisa (HOW MANY/HOW MUCH/WHEN)
CREATE OR REPLACE VIEW fact_order_items AS
SELECT
  oi.id AS order_item_id,
  oi.order_id,
  o.user_id,
  oi.product_id,
  oi.inventory_item_id,

  o.created_at AS order_created_at,
  oi.created_at AS item_created_at,
  oi.shipped_at AS item_shipped_at,
  oi.delivered_at AS item_delivered_at,
  oi.returned_at AS item_returned_at,

  LOWER(o.status) AS order_status,
  LOWER(oi.status) AS item_status,
  LOWER(COALESCE(oi.status, o.status)) AS status,

  1::int AS quantity,
  p.retail_price::numeric AS unit_price,
  p.cost::numeric AS unit_cost,
  (1 * p.retail_price)::numeric AS revenue,
  (1 * p.cost)::numeric AS cogs,
  (1 * (p.retail_price - p.cost))::numeric AS gross_margin,

  CASE WHEN oi.shipped_at   IS NULL THEN 0 ELSE 1 END AS is_shipped,
  CASE WHEN oi.delivered_at IS NULL THEN 0 ELSE 1 END AS is_delivered,
  CASE WHEN oi.returned_at  IS NULL THEN 0 ELSE 1 END AS is_returned
  
FROM order_items oi
JOIN orders o   ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.id;

----- 3. build analytical layer - final denormalized 
--------- about tabel vw_sales_anaytics:
		  -- table/view yang menggabungkan fact + dimensi menjadi satu dataset untuk digunakan
		     -- contain:
		  		-- * kolom penting	: fact_order_items, dim_users, dim_products, dim_distribution_centers
--------- tujuan/peruntukan: 
		  -- * memudahkan EDA, dashboard, dan deployment
		  -- * mengurangi kompleksitas join di python/powerBI/streamlit
		  -- * meningkatkan performa dan kecepatan eksplorasi
CREATE OR REPLACE VIEW vw_sales_analytics AS
SELECT
  f.order_item_id,
  f.order_id,
  f.user_id,
  f.product_id,
  f.inventory_item_id,

  f.order_created_at,
  f.item_created_at,
  f.item_shipped_at,
  f.item_delivered_at,
  f.item_returned_at,
  f.status,

  u.gender AS user_gender,
  u.age AS user_age,
  u.city AS user_city,
  u.state AS user_state,
  u.country AS user_country,
  u.traffic_source AS user_traffic_source,
  u.user_created_at,

  p.product_name,
  p.product_brand,
  p.product_category,
  p.product_department,
  p.product_sku,
  p.product_cost,
  p.product_retail_price,
  p.distribution_center_id,

  dc.distribution_center_name,
  dc.dc_latitude,
  dc.dc_longitude,

  f.quantity,
  f.unit_price,
  f.unit_cost,
  f.revenue,
  f.cogs,
  f.gross_margin,
  f.is_shipped,
  f.is_delivered,
  f.is_returned

FROM fact_order_items f
JOIN dim_users u ON f.user_id = u.user_id
JOIN dim_products p ON f.product_id = p.product_id
LEFT JOIN dim_distribution_centers dc
  ON p.distribution_center_id = dc.distribution_center_id;

---------------------------------------------------------------------------------------
-- 5) SANITY CHECK
---------------------------------------------------------------------------------------	

----- 5.1 check baris tabel fact
select count (*) as n_fact from fact_order_items; --- result: 181.759

----- 5.2 check baris tabel view final
select count (*) as n_sales_view from vw_sales_analytics;--- result: 181.759

----- notes:
		-- hasil pengecekan baris dari tabel fact_order_items dan vw_sales_analytics sama
		-- artinya tidak ada baris yang hilang atau terduplikasi saat denormalisasi

----- 5.3 check total revenue and margin
select 
	sum(revenue) as total_revenue,			--- result: 10.827.118,91
	sum(gross_margin) as total_gross_margin --- result:  5.618.763,69
from vw_sales_analytics;

----- notes:
		-- hasil pengecekan menunjukan gross margin 52%
		-- hal ini masih dapat dikatakan wajar karena tidak ada indikasi revenue negatif, margin>revenue, margin = 0

----- 5.4 check check status distribusi
select status,count(*)
from vw_sales_analytics
group by status
order by count(*) desc;
		--- result:
				-- * shipped	: 54.440
				-- * complete	: 45.609
				-- * processing	: 36.388
				-- * cancelled	: 27.090
				-- * returned	: 18.232
----- notes:
		-- distribusi masih terbilang masuk akal secara bisnis dengan returned pengembalian 10% dari total

----- 5.5 check top catergory by revenue
select product_category, sum(revenue) as revenue
from vw_sales_analytics
group by product_category
order by revenue desc 
limit 10;
		--- result:
				-- * outerwear & coats				: 1.301.507,72
				-- * jeans							: 1.253.644,21
				-- * sweaters						:   842.651,47
				-- * suits & sport coats			:   666.767,31
				-- * fashion hoodies & sweatshirts	:   649.352,82
				-- * swims							:   646.738,72
				-- * sleep & lounge					:   537.392,10
				-- * shorts							:   512.069,48
				-- * tops & tees					:   491.551,39
				-- * dresses						:   464.416,84

----- notes:
		-- pola penjualan terbilang konsisten untuk retail appareal
		-- tidak ada kategori  "random" yang tiba tiba mendominasi
		-- pola distribusi terbilang tidak terlalu eksterim, dalam artian tidak ada 1 kategori yang menyedot > 50% penjualan

-------- final notes for sanity check
----------- ALL ANALYTICAL TABLES PASSEED SANITY CHECKS AND WERE FINALIZED FOR DOWNSTREAM ANALYSIS

---- for analysis we use table vw_sales_analytics

select * from vw_sales_analytics;

select * from fact_order_items;


















