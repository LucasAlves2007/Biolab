USE biolab;

-- =====================================
-- DESATIVAR VERIFICAÇÃO DE FK
-- =====================================

SET FOREIGN_KEY_CHECKS = 0;

-- =====================================
-- ZERAR TABELAS RELACIONADAS
-- =====================================

TRUNCATE TABLE resultado;

TRUNCATE TABLE solicitacao_exame;

TRUNCATE TABLE inconsistencia;

TRUNCATE TABLE solicitacao;

-- =====================================
-- REATIVAR VERIFICAÇÃO DE FK
-- =====================================

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================
-- CONSULTA 1
-- TAT por exame/canal e identificar gargalos
-- =====================================

WITH base AS (
    SELECT
        e.descricao_exame AS exame,
        s.canal,

        TIMESTAMPDIFF(MINUTE, s.timestamp_solicitacao, s.timestamp_coleta) AS t_coleta,
        TIMESTAMPDIFF(MINUTE, s.timestamp_coleta, s.timestamp_processamento) AS t_processamento,
        TIMESTAMPDIFF(MINUTE, s.timestamp_processamento, s.timestamp_validacao) AS t_validacao,
        TIMESTAMPDIFF(MINUTE, s.timestamp_validacao, s.timestamp_liberacao) AS t_liberacao,

        TIMESTAMPDIFF(MINUTE, s.timestamp_solicitacao, s.timestamp_liberacao) AS tempo_total

    FROM solicitacao s

    INNER JOIN solicitacao_exame se
        ON s.id_solicitacao = se.id_solicitacao

    INNER JOIN exame e
        ON se.id_exame = e.id_exame

    WHERE
        s.timestamp_solicitacao IS NOT NULL
        AND s.timestamp_coleta IS NOT NULL
        AND s.timestamp_processamento IS NOT NULL
        AND s.timestamp_validacao IS NOT NULL
        AND s.timestamp_liberacao IS NOT NULL

        AND s.timestamp_coleta >= s.timestamp_solicitacao
        AND s.timestamp_processamento >= s.timestamp_coleta
        AND s.timestamp_validacao >= s.timestamp_processamento
        AND s.timestamp_liberacao >= s.timestamp_validacao
),

stats AS (
    SELECT
        exame,
        canal,
        tempo_total,
        t_coleta,
        t_processamento,
        t_validacao,
        t_liberacao,

        ROW_NUMBER() OVER (
            PARTITION BY exame, canal
            ORDER BY tempo_total
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY exame, canal
        ) AS total

    FROM base
)

SELECT
    exame,
    canal,

    ROUND(AVG(tempo_total), 2) AS media_total,

    ROUND(AVG(t_coleta), 2) AS media_coleta,
    ROUND(AVG(t_processamento), 2) AS media_processamento,
    ROUND(AVG(t_validacao), 2) AS media_validacao,
    ROUND(AVG(t_liberacao), 2) AS media_liberacao,

    -- P50
    MAX(CASE
        WHEN rn = CEIL(total * 0.5) THEN tempo_total
    END) AS p50,

    -- P90
    MAX(CASE
        WHEN rn = CEIL(total * 0.9) THEN tempo_total
    END) AS p90,

    -- GARGALO OPERACIONAL
    CASE
        WHEN GREATEST(
            AVG(t_coleta),
            AVG(t_processamento),
            AVG(t_validacao),
            AVG(t_liberacao)
        ) = AVG(t_coleta)
        THEN 'SOLICITACAO → COLETA'

        WHEN GREATEST(
            AVG(t_coleta),
            AVG(t_processamento),
            AVG(t_validacao),
            AVG(t_liberacao)
        ) = AVG(t_processamento)
        THEN 'COLETA → PROCESSAMENTO'

        WHEN GREATEST(
            AVG(t_coleta),
            AVG(t_processamento),
            AVG(t_validacao),
            AVG(t_liberacao)
        ) = AVG(t_validacao)
        THEN 'PROCESSAMENTO → VALIDACAO'

        ELSE 'VALIDACAO → LIBERACAO'
    END AS gargalo_operacional

FROM stats

GROUP BY
    exame,
    canal

ORDER BY
    media_total DESC;
    
--
-- teste 1
--
SELECT
    e.descricao_exame AS exame,
    s.canal,

    TIMESTAMPDIFF(MINUTE, s.timestamp_solicitacao, s.timestamp_liberacao) AS tempo_total,

    ROW_NUMBER() OVER (
        PARTITION BY e.descricao_exame, s.canal
        ORDER BY TIMESTAMPDIFF(MINUTE, s.timestamp_solicitacao, s.timestamp_liberacao)
    ) AS ranking

FROM solicitacao s

INNER JOIN solicitacao_exame se
    ON s.id_solicitacao = se.id_solicitacao

INNER JOIN exame e
    ON se.id_exame = e.id_exame

ORDER BY
    exame, canal, tempo_total;