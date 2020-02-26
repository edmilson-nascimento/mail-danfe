[![N|Solid](https://wiki.scn.sap.com/wiki/download/attachments/1710/ABAP%20Development.png?version=1&modificationDate=1446673897000&api=v2)](https://www.sap.com/brazil/developer.html)

# DANFe por e-mail #

## Necessidade ##
Foi solicitado que fosse criado um programa, que tivesse como filtro dados de de Nota Fiscal (como Número de Documento) e que a partir do resultado dessa busca, o Danfe dessas Notas Fiscais, fossem enviados por e-mail em formato PDF.

## Tecnologia ##
Para que seja feito isso de forma a aproveitar os recursos, de acordo como são usados na na transação J1BNFE, serão utilizadas as mesmas rotinas que são utilizadas para gerar o Danfe nessa transação. O desafio principal então fica para "simular" a mesma chamada de rotina da criação do `Smartforms` que é chamada já nas transações J1B3N e J1BNFE.

## Solução proposta ##
As rotinas que hoje existem para chamada do `Smartforms` não foram alteradas ~~porque eu não sou obrigado fazer melhorias que estão fora do escope que estou atuando~~ para que não houvessem impactos em outras áreas. Algumas mensagens de tela, pode ser problema. Isso reforça uma nota que, as mensagens e log's devem ser tratados para execuções _online_ (o usuário executando e aguardando o resultado) e também devem ser tratadas quando há execuções em _background_. Envio do DANFE, em um arquivo PDF por e-mail.

### Informaćoes importantes ##
Eu tentei encapsular a solução toda em uma classe criada na `SE24` mas por alguma limitação da linguagem ou outro motivo ~~já que tudo é pra ontem, as vezes falta tempo de criar a melhor solução~~, foi feito com uma classe local dentro de um report para que sejam alimentadas as informações da Tabela `NAST` *[Status da mensagem]*, conforme trecho abaixo.

```abap
    free nast .
    nast-kappl = tnapr_line-kappl . " Aplicação para condições de mensagens
    nast-objky = doc_line-docnum .  " Chave de objeto
    nast-kschl = tnapr_line-kschl . " Tipo de mensagem
    nast-spras = sy-langu .         " Idioma da mensagem
    nast-erdat = sy-datum .         " Data da criação do registro de status
    nast-eruhr = sy-uzeit .         " Status da mensagem
    nast-nacha = 1 .                " Meio de transmissão de uma mensagem (1   Saída de impressão)
    nast-anzal = 1 .                " Nº de mensagens (original + cópias)
    nast-vsztp = 1 .                " Momento do envio (1  Enviar através de jobs escalonados periodicamente)
    nast-nauto = abap_on .          " Mensagem determinada através das condições

    nast-dimme = abap_on .          " Saída imediata
    nast-ldest = 'ZPDF' .           " Spool: dispositivo de saída (valor temporariamente fixo)
```
