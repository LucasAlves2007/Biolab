USE biolab;

-- =====================================
-- CONSULTA 1
-- RESULTADOS FORA DA REFERÊNCIA
-- =====================================

SELECT
    r.id_resultado,

    p.nome AS paciente,

    p.genero,

    TIMESTAMPDIFF(YEAR, p.data_nasc, CURDATE()) AS idade,

    e.descricao_exame AS exame,

    r.valor_obtido,

    tr.valor_referencia_min,

    tr.valor_referencia_max,

    r.situacao_resultado,

    CASE
        WHEN r.valor_obtido < tr.valor_referencia_min THEN 'ABAIXO'

        WHEN r.valor_obtido > tr.valor_referencia_max THEN 'ACIMA'

        ELSE 'NORMAL'
    END AS comparacao_referencia

FROM resultado r

INNER JOIN solicitacao s
    ON r.id_solicitacao = s.id_solicitacao

INNER JOIN paciente p
    ON s.id_paciente = p.id_paciente

INNER JOIN exame e
    ON r.id_exame = e.id_exame

INNER JOIN tabela_referencia tr
    ON r.id_exame = tr.id_exame

    AND p.genero = tr.sexo

    AND TIMESTAMPDIFF(YEAR, p.data_nasc, CURDATE())
        BETWEEN tr.idade_min AND tr.idade_max;

-- =====================================
-- CONSULTA 2
-- Taxa de Repetição e Custo Estimado
-- =====================================

SELECT 
    i.descricao_inconsistencia AS motivo_inconsistencia,
    GROUP_CONCAT(DISTINCT s.id_solicitacao) AS solicitacoes_afetadas,
    COUNT(i.id_inconsistencia) AS quantidade_repeticoes,
    SUM(i.custo_interno) AS impacto_financeiro,
    ROUND(AVG(i.custo_interno), 2) AS custo_medio
FROM 
    inconsistencia i
JOIN 
    solicitacao s ON i.id_solicitacao = s.id_solicitacao
JOIN 
    resultado r ON s.id_solicitacao = r.id_solicitacao
GROUP BY 
    i.descricao_inconsistencia
ORDER BY 
    impacto_financeiro DESC;