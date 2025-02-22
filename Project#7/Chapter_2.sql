1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года.
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
WITH tab AS (
SELECT DATE_TRUNC('month', creation_date)::date AS mon,
       SUM(views_count) AS cnt_reg
FROM stackoverflow.posts
--WHERE creation_date::date BETWEEN '2008-01-01' AND '2008-12-31'
GROUP BY mon --EXTRACT(MONTH FROM creation_date::date)
ORDER BY 2 DESC)
SELECT * 
FROM tab; 

2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте.
Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON u.id = p.user_id
JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id
WHERE pt.type = 'Answer'
      AND (p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month'))
GROUP BY u.display_name
HAVING COUNT(p.id) > 100;

3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года.
Отсортируйте таблицу по значению месяца по убыванию.
SELECT COUNT(DISTINCT p.id),
       DATE_TRUNC('month', p.creation_date)::date AS mon       
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON u.id = p.user_id
JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id
WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01' --u.creation_date BETWEEN '2008-09-01' AND '2008-09-30'
      AND u.id IN (SELECT user_id
                 FROM stackoverflow.posts
                 WHERE DATE_TRUNC('month', creation_date)::date = '2008-12-01') --creation_date BETWEEN '2008-12-01' AND '2008-12-31')
GROUP BY mon
HAVING COUNT(p.id) > 0
ORDER BY 2 DESC;

4. Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT user_id, 
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts;

5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат.
WITH tab AS (
SELECT user_id, 
       COUNT(DISTINCT creation_date::date) AS cc
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
GROUP BY user_id)
SELECT ROUND(AVG(tab.cc))
FROM tab;

6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз.
Чтобы этого избежать, переведите делимое в тип numeric.
WITH month_post AS (SELECT EXTRACT(MONTH from creation_date::date) AS month,
                    COUNT(DISTINCT id)    
                    FROM stackoverflow.posts
                    WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
                    GROUP BY month)

SELECT *,
       ROUND(((count::numeric / LAG(count) OVER (ORDER BY month)) - 1) * 100, 2) AS user_growth
FROM month_post;

7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.
WITH user_post AS (SELECT user_id,
                   COUNT(DISTINCT id) AS cnt
                   FROM stackoverflow.posts
                   GROUP BY user_id
                   ORDER BY cnt DESC
                   LIMIT 1),

     dtt AS (SELECT p.user_id,
             p.creation_date,
             extract('week' from p.creation_date) AS week_number
             FROM stackoverflow.posts AS p
             JOIN user_post ON user_post.user_id = p.user_id
             WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01')

SELECT DISTINCT week_number::numeric,
       MAX(creation_date) OVER (PARTITION BY week_number) AS post_dt
FROM dtt
ORDER BY week_number;
