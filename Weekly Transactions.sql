with x as (

SELECT 1 as index, 'daily' as time_interval, COUNT(*) as num_txns, count(distinct sender_address) as unique_addresses
FROM starknet.transactions 
WHERE block_time > NOW() - interval '1' day
UNION ALL
SELECT 2 as index, 'weekly' as time_interval, COUNT(*) as num_txns, count(distinct sender_address) as unique_addresses
FROM starknet.transactions 
WHERE block_time > NOW() - interval '7' day
UNION ALL
SELECT 3 as index, 'monthly' as time_interval, COUNT(*) as num_txns, count(distinct sender_address) as unique_addresses
FROM starknet.transactions 
WHERE block_time > NOW() - interval '30' day
)
SELECT *
FROM x
ORDER BY index
