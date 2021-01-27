*&---------------------------------------------------------------------*
*& Report zdemo_excel47
*&---------------------------------------------------------------------*
*&
*& - BIND_TABLE and Calculated Column Formulas
*& - Ignore cell errors
*&
*&---------------------------------------------------------------------*
REPORT zdemo_excel47.

DATA: lo_excel     TYPE REF TO zcl_excel,
      lo_worksheet TYPE REF TO zcl_excel_worksheet,
      lo_hyperlink TYPE REF TO zcl_excel_hyperlink,
      lo_column    TYPE REF TO zcl_excel_column.

CONSTANTS: gc_save_file_name TYPE string VALUE '47_CalculatedColumns.xlsx'.
INCLUDE zdemo_excel_outputopt_incl.

CLASS lcl_app DEFINITION.
  PUBLIC SECTION.

    METHODS main
      RAISING
        zcx_excel.

ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD main.

    TYPES: BEGIN OF ty_data,
             carrid               TYPE sflight-carrid,
             connid               TYPE sflight-connid,
             fldate               TYPE sflight-fldate,
             price                TYPE sflight-price,
             formula              TYPE string,
             calculated_formula   TYPE string,
             calculated_formula_2 TYPE sflight-price,
             calculated_formula_3 TYPE sflight-price,
             calculated_formula_4 TYPE sflight-price,
           END OF ty_data.
    DATA: lv_f1             TYPE string,
          lv_f2             TYPE string,
          ls_data           TYPE ty_data,
          lt_data           TYPE STANDARD TABLE OF ty_data,
          lt_field_catalog  TYPE zexcel_t_fieldcatalog,
          ls_catalog        TYPE zexcel_s_fieldcatalog,
          ls_table_settings TYPE zexcel_s_table_settings,
          ls_ignored_errors TYPE zcl_excel_worksheet=>mty_s_ignored_errors,
          lt_ignored_errors TYPE zcl_excel_worksheet=>mty_th_ignored_errors,
          lo_range          TYPE REF TO zcl_excel_range.
    .
    FIELD-SYMBOLS: <ls_field_catalog> TYPE zexcel_s_fieldcatalog.

    " Load data
    lv_f1 = 'TblFlights[[#This Row],[Airfare]]+100'. " [@Airfare]+100
    lv_f2 = 'TblFlights[[#This Row],[Airfare]]+222'. " [@Airfare]+222
    ls_data-carrid = `AA`. ls_data-connid = '0017'. ls_data-fldate = '20180116'. ls_data-price = '422.94'. ls_data-formula = lv_f1. ls_data-calculated_formula = lv_f2.
    APPEND ls_data TO lt_data.
    ls_data-carrid = `AZ`. ls_data-connid = '0555'. ls_data-fldate = '20180116'. ls_data-price = '185.00'. ls_data-formula = lv_f1. ls_data-calculated_formula = lv_f1.
    APPEND ls_data TO lt_data.
    ls_data-carrid = `LH`. ls_data-connid = '0400'. ls_data-fldate = '20180119'. ls_data-price = '666.00'. ls_data-formula = lv_f1. ls_data-calculated_formula = lv_f2.
    APPEND ls_data TO lt_data.
    ls_data-carrid = `UA`. ls_data-connid = '0941'. ls_data-fldate = '20180117'. ls_data-price = '879.82'. ls_data-formula = lv_f1. ls_data-calculated_formula = lv_f2.
    APPEND ls_data TO lt_data.

    " Creates active sheet
    CREATE OBJECT lo_excel.

    " Get active sheet
    lo_worksheet = lo_excel->get_active_worksheet( ).

    lt_field_catalog = zcl_excel_common=>get_fieldcatalog( ip_table = lt_data ).

    LOOP AT lt_field_catalog ASSIGNING <ls_field_catalog>.
      CASE <ls_field_catalog>-fieldname.
          " No formula
        WHEN 'PRICE'.
          <ls_field_catalog>-totals_function = zcl_excel_table=>totals_function_average.
          " Each cell may have a distinct formula, none formula is applied to future new rows
        WHEN 'FORMULA'.
          <ls_field_catalog>-scrtext_m       = 'Formula and aggregate function'.
          <ls_field_catalog>-formula         = abap_true.
          <ls_field_catalog>-totals_function = zcl_excel_table=>totals_function_sum.
          " each cell may have a distinct formula, a formula is applied to future new rows
        WHEN 'CALCULATED_FORMULA'.
          <ls_field_catalog>-scrtext_m       = 'Calculated formula except one and aggregate function'.
          <ls_field_catalog>-formula         = abap_true.
          <ls_field_catalog>-column_formula  = lv_f2.
          <ls_field_catalog>-totals_function = zcl_excel_table=>totals_function_min.
          " The column formula applies to all rows and to future new rows
        WHEN 'CALCULATED_FORMULA_2'.
          <ls_field_catalog>-scrtext_m       = 'Calculated formula'.
          <ls_field_catalog>-column_formula  = 'D2+100'.
          " The column formula applies to all rows and to future new rows
        WHEN 'CALCULATED_FORMULA_3'.
          <ls_field_catalog>-scrtext_m       = 'Calculated formula and aggregate function'.
          <ls_field_catalog>-column_formula  = 'D2+100'.
          <ls_field_catalog>-totals_function = zcl_excel_table=>totals_function_max.
        WHEN 'CALCULATED_FORMULA_4'.
          <ls_field_catalog>-scrtext_m       = 'Calculated formula with array function and named range'.
          <ls_field_catalog>-column_formula  = 'A1&";"&_xlfn.IFS(TRUE,NamedRange)'. " =A1&";"&@IFS(TRUE,NamedRange)
      ENDCASE.
    ENDLOOP.

    ls_table_settings-table_style         = zcl_excel_table=>builtinstyle_medium2.
    ls_table_settings-table_name          = 'TblFlights'.
    ls_table_settings-top_left_column     = 'A'.
    ls_table_settings-top_left_row        = 1.
    ls_table_settings-show_row_stripes    = abap_true.

    lo_worksheet->bind_table(
        ip_table          = lt_data
        it_field_catalog  = lt_field_catalog
        is_table_settings = ls_table_settings ).

    " Give one cell of the calculated column a different value and ignore the error "inconsistent calculated column formula"
    lo_worksheet->set_cell( ip_column = 7 ip_row = 2 ip_value = 'Text' ). " cell 'G2'
    CLEAR ls_ignored_errors.
    ls_ignored_errors-cell_coords = 'G2'.
    ls_ignored_errors-calculated_column = abap_true.
    INSERT ls_ignored_errors INTO TABLE lt_ignored_errors.
    lo_worksheet->set_ignored_errors( lt_ignored_errors ).

    " Numbers stored as texts
    CLEAR ls_ignored_errors.
    ls_ignored_errors-cell_coords = 'B2:B5'.
    ls_ignored_errors-number_stored_as_text = abap_true.
    INSERT ls_ignored_errors INTO TABLE lt_ignored_errors.
    lo_worksheet->set_ignored_errors( lt_ignored_errors ).

    " Named range for formula 4
    lo_range = lo_excel->add_new_range( ).
    lo_range->name = 'NamedRange'.
    lo_range->set_value( ip_sheet_name    = lo_worksheet->get_title( )
                         ip_start_column  = 'B'
                         ip_start_row     = 1
                         ip_stop_column   = 'B'
                         ip_stop_row      = 1 ).

*** Create output
    lcl_output=>output( lo_excel ).

  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  DATA: go_app   TYPE REF TO lcl_app,
        go_error TYPE REF TO zcx_excel.
  TRY.
      CREATE OBJECT go_app.
      go_app->main( ).
    CATCH zcx_excel INTO go_error.
      MESSAGE go_error TYPE 'I' DISPLAY LIKE 'E'.
  ENDTRY.
