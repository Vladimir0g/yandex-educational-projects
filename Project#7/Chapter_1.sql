1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки
SELECT COUNT(po.id)
FROM stackoverflow.posts AS po
JOIN stackoverflow.post_types AS pot ON po.post_type_id = pot.id
WHERE pot.type = 'Question' AND (score > 300 OR favorites_count >= 100); 

2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
WITH 
      q AS (
SELECT COUNT(po.id) AS count_q
FROM stackoverflow.posts AS po
JOIN stackoverflow.post_types AS pot ON po.post_type_id = pot.id
WHERE pot.type = 'Question' 
      AND  (EXTRACT(YEAR FROM creation_date) = 2008 
           AND EXTRACT(MONTH FROM creation_date) = 11
           AND EXTRACT(DAY FROM creation_date) BETWEEN 1 AND 18) 
GROUP BY EXTRACT(DAY FROM creation_date))
SELECT ROUND(AVG(count_q))
FROM q;

3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
SELECT COUNT(DISTINCT(u.id))
FROM stackoverflow.badges AS b
JOIN stackoverflow.users AS u ON b.user_id = u.id
WHERE u.creation_date::date = b.creation_date::date;

4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
WITH qqq AS(
SELECT COUNT(p.id) AS co
FROM stackoverflow.posts AS p
JOIN stackoverflow.votes AS v ON v.user_id = p.id
JOIN stackoverflow.users AS u ON p.user_id = u.id
WHERE u.display_name = 'Joel Coehoorn'
     AND v.id > 0
GROUP BY p.id)
SELECT COUNT(CO)
FROM qqq;

5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке.
Таблица должна быть отсортирована по полю id.
SELECT *, RANK()OVER (ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id;

6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
SELECT u.id, COUNT(vt.name)
FROM stackoverflow.users AS u
JOIN stackoverflow.votes AS v ON v.user_id = u.id
JOIN stackoverflow.vote_types AS vt ON v.vote_type_id = vt.id
WHERE vt.name = 'Close'
GROUP BY u.id
ORDER BY 2 DESC, 1 DESC
LIMIT 10;

7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
WITH tab AS (
SELECT u.id, 
       COUNT(b.id) AS c_bs
FROM stackoverflow.users AS u
JOIN stackoverflow.badges AS b ON b.user_id = u.id
WHERE b.creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY u.id
ORDER BY 2 DESC, 1
LIMIT 10)
SELECT *, 
       DENSE_RANK() OVER (ORDER BY c_bs DESC) AS r_k 
FROM tab;

8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id)) AS avg_score
FROM stackoverflow.posts
WHERE score != 0 
      AND title IS NOT NULL;

9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список.
WITH userss AS (
SELECT user_id
FROM stackoverflow.badges
GROUP BY user_id
HAVING COUNT(id) > 1000
)
SELECT title
FROM stackoverflow.posts
WHERE title IS NOT NULL
      AND user_id IN (SELECT user_id FROM userss);

10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
WITH userss AS (
SELECT id,
       views,
       CASE
          WHEN views >= 350 THEN 1
          WHEN views < 100 THEN 3
          ELSE 2
       END as groupe
FROM stackoverflow.users
WHERE location LIKE '%Canada%'
      AND views > 0
)
SELECT *
FROM userss;

11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
WITH userss AS (
SELECT d.id,
       d.views,
       d.groupe,
       MAX(d.views) OVER (PARTITION BY d.groupe) AS max2
FROM (
SELECT id,
       views,
       CASE
          WHEN views >= 350 THEN 1
          WHEN views < 100 THEN 3
          ELSE 2
       END as groupe
FROM stackoverflow.users
WHERE location LIKE '%Canada%'
      AND views > 0) AS d
)
SELECT userss.id,
       userss.views,
       userss.groupe  
FROM userss
WHERE userss.views = userss.max2
ORDER BY 2 DESC, 1;

12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.
WITH tab AS (
SELECT EXTRACT(DAY FROM creation_date::date) AS days,
       COUNT(id) AS cnt_reg
FROM stackoverflow.users
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY EXTRACT(DAY FROM creation_date::date))
SELECT *,
       SUM(tab.cnt_reg) OVER (ORDER BY tab.days) as cnt_users
FROM tab; 

13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.
WITH tab AS (
SELECT DISTINCT user_id,
       MIN(creation_date) OVER (PARTITION BY user_id) as first_post
FROM stackoverflow.posts
)
SELECT tab.user_id,
       (tab.first_post - u.creation_date) AS time_reg_post
FROM stackoverflow.users AS u
JOIN tab ON u.id = tab.user_id;
