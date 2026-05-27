USE biolab;

-- =====================================
-- CONSULTA 4
-- PRODUTIVIDADE E CARGA DE TRABALHO
-- POR BIOMÉDICO
-- =====================================

SELECT

    dados.semana_ano,

    dados.biomedico,

    dados.quantidade_exames,

    dados.total_pontos_complexidade,

    ROUND(est.media_geral, 2) AS media_geral,

    ROUND(est.desvio_padrao, 2) AS desvio_padrao,

    CASE

        WHEN dados.total_pontos_complexidade >
            (est.media_geral + (2 * est.desvio_padrao))

        THEN 'SOBRECARGA'

        ELSE 'NORMAL'

    END AS status_carga

FROM (

    SELECT

        YEARWEEK(
            s.timestamp_validacao,
            1
        ) AS semana_ano,

        b.id_biomedico,

        b.nome AS biomedico,

        COUNT(r.id_resultado) AS quantidade_exames,

        SUM(e.pontos_complexidade) AS total_pontos_complexidade

    FROM resultado r

    INNER JOIN biomedico b
        ON r.id_biomedico = b.id_biomedico

    INNER JOIN exame e
        ON r.id_exame = e.id_exame

    INNER JOIN solicitacao s
        ON r.id_solicitacao = s.id_solicitacao

    WHERE
        s.timestamp_validacao IS NOT NULL

    GROUP BY

        YEARWEEK(
            s.timestamp_validacao,
            1
        ),

        b.id_biomedico,
        b.nome

) AS dados

CROSS JOIN (

    SELECT

        AVG(sub.total_pontos) AS media_geral,

        STDDEV(sub.total_pontos) AS desvio_padrao

    FROM (

        SELECT

            SUM(e.pontos_complexidade) AS total_pontos

        FROM resultado r

        INNER JOIN exame e
            ON r.id_exame = e.id_exame

        INNER JOIN solicitacao s
            ON r.id_solicitacao = s.id_solicitacao

        GROUP BY

            YEARWEEK(
                s.timestamp_validacao,
                1
            ),

            r.id_biomedico

    ) AS sub

) AS est

ORDER BY

    dados.total_pontos_complexidade DESC,
    dados.semana_ano;