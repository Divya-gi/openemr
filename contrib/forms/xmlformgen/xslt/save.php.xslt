<?xml version="1.0" encoding="ISO-8859-1"?>
<!-- Generated by Hand -->
<!--
Copyright (C) 2011 Julia Longtin <julia.longtin@gmail.com>

This program is free software; you can redistribute it and/or
Modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
 -->
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:include href="common_objects.xslt"/>
<xsl:strip-space elements="*"/>
<xsl:template match="/">
<xsl:apply-templates select="form"/>
</xsl:template>
<!-- The variable telling field_objects.xslt what form is calling it -->
<xsl:variable name="page">save</xsl:variable>
<!-- if fetchrow has contents, a variable with that name will be created by field_objects.xslt, and all fields created by it will retreive values from it. -->
<xsl:variable name="fetchrow">xyzzy</xsl:variable>
<xsl:template match="form">
<xsl:text disable-output-escaping="yes"><![CDATA[<?php
/* this page is intended to be the 'action=' target of a form object.
 * it is called to save the contents of the form into the database
 */

/* for $GLOBALS[], ?? */
require_once('../../globals.php');
/* for acl_check(), ?? */
require_once($GLOBALS['srcdir'].'/api.inc');
/* for ??? */
require_once($GLOBALS['srcdir'].'/forms.inc');

]]></xsl:text>
<xsl:apply-templates select="table|RealName|safename|acl|layout"/>
<xsl:text disable-output-escaping="yes"><![CDATA[
/* an array of all of the fields' names and their types. */
$field_names = array(]]></xsl:text>
<xsl:for-each select="//field">
<xsl:text disable-output-escaping="yes"><![CDATA[']]></xsl:text>
<xsl:value-of select="@name" />
<xsl:text disable-output-escaping="yes"><![CDATA[' => ']]></xsl:text>
<xsl:value-of select="@type" />
<xsl:text disable-output-escaping="yes"><![CDATA[']]></xsl:text>
<xsl:if test="position()!=last()">,</xsl:if>
</xsl:for-each>
<xsl:text disable-output-escaping="yes"><![CDATA[);
/* an array of the lists the fields may draw on. */
$lists = array(]]></xsl:text>
<xsl:for-each select="//field[@type='checkbox_list' or @type='checkbox_combo_list' or @type='dropdown_list']">
<xsl:text disable-output-escaping="yes"><![CDATA[']]></xsl:text>
<xsl:value-of select="@name" />
<xsl:if test="@type='dropdown_list' or @type='checkbox_list' or @type='checkbox_combo_list'">
<xsl:text disable-output-escaping="yes"><![CDATA[' => ']]></xsl:text>
<xsl:variable name="i" select="@list"/>
<xsl:value-of select="//list[@name=$i]/@id"/>
<xsl:text disable-output-escaping="yes"><![CDATA[']]></xsl:text>
<xsl:if test="position()!=last()">, </xsl:if>
</xsl:if>
</xsl:for-each>
<xsl:text disable-output-escaping="yes"><![CDATA[);

/* get each field from $_POST[], storing them into $field_names associated with their names. */
foreach($field_names as $key=>$val)
{
    $pos = '';
    $neg = '';
    if ($val == 'textbox' || $val == 'textarea' || $val == 'provider' || $val == 'textfield')
    {
            $field_names[$key]=$_POST['form_'.$key];
    }
    if ($val == 'date')
    {
        $field_names[$key]=$_POST[$key];
    }
    if (($val == 'checkbox_list' ))
    {
        $field_names[$key]='';
        if (isset($_POST['form_'.$key]) && $_POST['form_'.$key] != 'none' ) /* if the form submitted some entries selected in that field */
        {
            $lres=sqlStatement("select * from list_options where list_id = '".$lists[$key]."' ORDER BY seq, title");
            while ($lrow = sqlFetchArray($lres))
            {
                if (is_array($_POST['form_'.$key]))
                    {
                        if ($_POST['form_'.$key][$lrow[option_id]])
                        {
                            if ($field_names[$key] != '')
                              $field_names[$key]=$field_names[$key].'|';
	                    $field_names[$key] = $field_names[$key].$lrow[option_id];
                        }
                    }
            }
        }
    }
    if (($val == 'checkbox_combo_list'))
    {
        $field_names[$key]='';
        if (isset($_POST['check_'.$key]) && $_POST['check_'.$key] != 'none' ) /* if the form submitted some entries selected in that field */
        {
            $lres=sqlStatement("select * from list_options where list_id = '".$lists[$key]."' ORDER BY seq, title");
            while ($lrow = sqlFetchArray($lres))
            {
                if (is_array($_POST['check_'.$key]))
                {
                    if ($_POST['check_'.$key][$lrow[option_id]])
                    {
                        if ($field_names[$key] != '')
                          $field_names[$key]=$field_names[$key].'|';
                        $field_names[$key] = $field_names[$key].$lrow[option_id].":xx".$_POST['form_'.$key][$lrow[option_id]];
                    }
                }
            }
        }
    }
    if (($val == 'dropdown_list'))
    {
        $field_names[$key]='';
        if (isset($_POST['form_'.$key]) && $_POST['form_'.$key] != 'none' ) /* if the form submitted some entries selected in that field */
        {
            $lres=sqlStatement("select * from list_options where list_id = '".$lists[$key]."' ORDER BY seq, title");
            while ($lrow = sqlFetchArray($lres))
            {
                if ($_POST['form_'.$key] == $lrow[option_id])
                {
                    $field_names[$key]=$lrow[option_id];
                    break;
                }
            }
        }
    }
}

/* at this point, field_names[] contains an array of name->value pairs of the fields we expected from the form. */

/* escape form data for entry to the database. */
foreach ($field_names as $k => $var) {
  $field_names[$k] = add_escape_custom($var);
}

if ($encounter == '') $encounter = date('Ymd');

if ($_GET['mode'] == 'new') {
    /* NOTE - for customization you can replace $_POST with your own array
     * of key=>value pairs where 'key' is the table field name and
     * 'value' is whatever it should be set to
     * ex)   $newrecord['parent_sig'] = $_POST['sig'];
     *       $newid = formSubmit($table_name, $newrecord, $_GET['id'], $userauthorized);
     */

    /* make sure we're at the beginning of the array */
    reset($field_names);

]]></xsl:text>
<xsl:if test="//table[@type='form']">
<xsl:text disable-output-escaping="yes"><![CDATA[    /* save the data into the form's encounter-based table */
    $newid = formSubmit($table_name, $field_names, $_GET['id'], $userauthorized);
]]></xsl:text>
</xsl:if>
<xsl:if test="//table[@type='extended']">
<xsl:text disable-output-escaping="yes"><![CDATA[    /* save the data into the form's table */
    /* construct our sql statement */
    $sql= 'insert into '.$table_name." set date = NOW(), pid = '".$_SESSION['pid']."',";
    foreach ($field_names as $k => $var) {
        $sql .= " $k = '$var',";
    }

    /* remove the last comma */
    $sql = substr($sql, 0, -1);

    /* insert into the table */
    $newid=sqlInsert($sql);

    if ($id!='') /* if we're passed an ID, update the old form_id to point to a new one. */
    {
      $sql= "update forms set date = NOW(), encounter='".$encounter."', form_name='".$form_name."', form_id='".$newid."', pid='".$pid."', user='".$_SESSION['authUser']."', groupname='".$_SESSION['authProvider']."', authorized='".$userauthorized."', formdir='".$form_folder."' where form_name='".$form_name."' and encounter='".$encounter."' and pid='".$pid."' and form_id='".$id."'";
      echo $sql;
      sqlStatement($sql);
    }
    else
]]></xsl:text>
</xsl:if>
<xsl:text disable-output-escaping="yes"><![CDATA[    /* link this form into the encounter. */
    addForm($encounter, $form_name, $newid, $form_folder, $pid, $userauthorized);
}
]]></xsl:text>
<xsl:if test="//table[@type='extended']">
<xsl:text disable-output-escaping="yes"><![CDATA[
elseif ($_GET['mode'] == 'update') {
    /* make sure we're at the beginning of the array */
    reset($field_names);

    /* save the data into the form's table */
    /* construct our sql statement */
    $sql= 'insert into '.$table_name." set date = NOW(), pid = '".$_SESSION['pid']."',";
    foreach ($field_names as $k => $var) {
        $sql .= " $k = '$var',";
    }

    /* remove the last comma */
    $sql = substr($sql, 0, -1);

    /* insert into the table */
    $newid=sqlInsert($sql);

if ($_GET['return'] == 'encounter') {
    /* link this form into the encounter. */
    addForm($encounter, $form_name, $newid, $form_folder, $pid, $userauthorized);
}
}
]]></xsl:text>
</xsl:if>
<xsl:if test="//table[@type='form']">
<xsl:text disable-output-escaping="yes"><![CDATA[
elseif ($_GET['mode'] == 'update') {
    /* make sure we're at the beginning of the array */
    reset($field_names);

    /* update the data in the form's table */
    $success = formUpdate($table_name, $field_names, $_GET['id'], $userauthorized);
    /* sqlStatement('update '.$table_name." set pid = {".$_SESSION['pid']."},groupname='".$_SESSION['authProvider']."',user='".$_SESSION['authUser']."',authorized=$userauthorized,activity=1,date = NOW(), where id=$id"); */
}
]]></xsl:text>
</xsl:if>
<xsl:text disable-output-escaping="yes"><![CDATA[

$_SESSION['encounter'] = $encounter;

formHeader('Redirecting....');
]]></xsl:text>
<xsl:if test="//table[@type='extended']">
<xsl:text disable-output-escaping="yes"><![CDATA[
if ($_GET['return'] == 'show') {
formJump("{$GLOBALS['rootdir']}/forms/".$form_folder.'/show.php');
]]></xsl:text>
<xsl:text disable-output-escaping="yes"><![CDATA[}
else
{
]]></xsl:text>
</xsl:if>
<xsl:if test="//table[@type='form' or @type='extended']">
<xsl:text disable-output-escaping="yes"><![CDATA[/* defaults to the encounters page. */
formJump();
]]></xsl:text>
</xsl:if>
<xsl:if test="//table[@type='extended']">
<xsl:text disable-output-escaping="yes"><![CDATA[}
]]></xsl:text>
</xsl:if>
<xsl:text disable-output-escaping="yes"><![CDATA[
formFooter();
?>
]]></xsl:text>
</xsl:template>
</xsl:stylesheet>
