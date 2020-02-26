report zmm_mail .

parameters:
  p_docnum type j_1bnfdoc-docnum obligatory .

tables:
  nast .

data:
  retcode            type sy-subrc,
  xscreen            type char1,
  otf                type ssfcrescl,
  lines              type fmlines,
  bin_file           type xstring,
  text               type soli_tab,

  mail               type ref to zcl_mail,
  attachment_type    type soodk-objtp value 'PDF',
  attachment_subject type sood-objdes value 'anexo',
  size               type so_obj_len,
  att_content_hex    type solix_tab.


* Seleciona o formulario das notas selecionadas
select single docnum,form
  from j_1bnfdoc
  into @data(doc_line)
 where docnum eq @p_docnum .

* Seleciona o programa de impressão da DANFE
if ( sy-subrc eq 0 ) .

  select *
   up to 1 rows
    from tnapr
    into @data(tnapr_line)
   where kschl eq @doc_line-form .
  endselect .


  if ( sy-subrc eq 0 ) .

*   Monta dados da Nast
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

*   Chama o perform do programa a ser utilizado para impressão da DANFE
    perform ('ENTRY_CKPIT_SEM') in program (tnapr_line-pgnam) using retcode xscreen .

*   Captura Tabela de Dados DANFE
    data(get_otf) = |({ tnapr_line-pgnam })IT_JOB_OUTPUT_INFO|.

    assign (get_otf) to field-symbol(<otf>).

    if ( <otf> is assigned ) .
      otf = <otf>.
    endif .

    if ( lines( otf-otfdata ) eq 0 ) .

    else .

*     Converte smartform OTF to PDF
      call function 'CONVERT_OTF'
        exporting
          format                = 'PDF'
*         max_linewidth         = 132
*         archive_index         = ' '
*         copynumber            = 0
*         ascii_bidi_vis2log    = ' '
*         pdf_delete_otftab     = ' '
*         pdf_username          = ' '
*         pdf_preview           = ' '
*         use_cascading         = ' '
*         modified_param_table  =
        importing
*         bin_filesize          =
          bin_file              = bin_file
        tables
          otf                   = otf-otfdata
          lines                 = lines
        exceptions
          err_max_linewidth     = 1
          err_format            = 2
          err_conv_not_possible = 3
          err_bad_otf           = 4
          others                = 5.

      if ( sy-subrc eq 0 ) .

      endif.

      if ( bin_file is initial ) .

      else .

        text = value #( ( line = 'Message mail.' ) ) .

        mail = new zcl_mail( obj_des = |E-mail - ABAP Development (Danfe { doc_line-docnum })| text = text ) .

        create object mail
          exporting
            obj_des = |E-mail - ABAP Development (Danfe { doc_line-docnum })|
            text    = text.

        att_content_hex = cl_bcs_convert=>xstring_to_solix( iv_xstring = bin_file ).

        mail->attachment(
          exporting
            attachment_type    = attachment_type
            attachment_subject = attachment_subject
            size               = size
            att_content_hex    = att_content_hex
        ).

        mail->send( recipient = 'nascimento@abapconsulting.com.br' ) .


        free nast.

      endif .

    endif .

  endif .

endif.
