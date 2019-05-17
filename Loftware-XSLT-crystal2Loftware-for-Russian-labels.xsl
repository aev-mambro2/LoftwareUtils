<?xml version="1.0" encoding="UTF-8" ?>
<!--
  - Transforms label printing instructions produced by Crystal Reports 
  - into an XML format understood by a Loftware label printer. 
  - This script is based on the User Guide for the Loftware Print Server 
  - version 11.1, (c) 2017 Loftware.
  - 
  - @author A.E.Veltstra, Mamiye Brothers LLC
  - @version 2019-04-01 12:27
-->
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:cr="urn:crystal-reports:schemas:report-detail" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xsi:schemaLocation="urn:crystal-reports:schemas:report-detail http://www.businessobjects.com/products/xml/CR2008Schema.xsd"
  version="1.0">
  <xsl:output method="xml" indent="yes" encoding="UTF-8" standalone="yes" />
  <xsl:param name="nsLoft" select="'http://www.loftware.com/schemas'"/>

  <!-- Suppress any text that this script does not call for explicitly -->
  <xsl:template match="//text()"/>

  <!-- Crystal Reports produces its own root. Lofware needs a different root. -->
  <xsl:template match="/cr:CrystalReport">
    <xsl:element name="labels" namespace="{$nsLoft}">
      <!-- These default attributes will get overridden by instructions for each label. -->
      <xsl:attribute name="_FORMAT">Russia.lwl</xsl:attribute>
      <xsl:attribute name="_JOBNAME">RussianLabelJob001</xsl:attribute>
      <xsl:attribute name="_QUANTITY">1</xsl:attribute>
      <xsl:apply-templates select="cr:Details[@Level='1']"/>
    </xsl:element>
  </xsl:template>

  <!-- Just in case Crystal Reports decides to provide more levels of Details, 
       this criteria limits processing to Level 1.  -->
  <xsl:template match="cr:Details[@Level='1']">
    <xsl:element name="label" namespace="{$nsLoft}">
      <!-- Instruction sections turn into XML attributes. XSLT requires that attributes get 
           produced prior to elements, and therefore this script processes the instructions first. -->
      <xsl:apply-templates select="cr:Section" mode="instructions"/>
      <xsl:apply-templates select="cr:Section" mode="data"/>
    </xsl:element>
  </xsl:template>

  <!-- The 0th section contains the label format. Since that is always going to be
       the same (russia.lwl), this statement suppresses processing of that section.  -->
  <xsl:template match="cr:Section[@SectionNumber = 0]"/>

  <!-- Label instructions override the defaults. -->
  <xsl:template match="cr:Section" mode="instructions">
    <!-- A section is a printer instruction if the 1st TextValue of the 1st Text starts with *PRINTERNUMBER.
         A printer instruction section has 2 Text elements. -->
    <xsl:variable name="pVal" select="string(cr:Text[1]/cr:TextValue[1]/text())" />
    <xsl:if test="starts-with($pVal, '*PRINTERNUMBER')">
      <xsl:call-template name="printer_instruction"/>
    </xsl:if>
    <!-- A section is a quantity instruction if the Field[@Name="Quantity1"].
         A quantity instruction section has a Value element that contains the amount of labels to print. -->
    <xsl:if test="cr:Field[@Name='Quantity1']">
      <xsl:call-template name="quantity_instruction"/>
    </xsl:if>
  </xsl:template>

  <!-- Label printer instructions override the defaults, sets which printer will be printing the label. -->
  <xsl:template name="printer_instruction">
    <xsl:variable name="value" select="translate(string(./cr:Text[1]/cr:TextValue[1]/text()), '*PRINTERNUMBER, ', '')" />
    <xsl:attribute name="_PRINTERNUMBER">
      <xsl:copy-of select="$value"/>
    </xsl:attribute>
  </xsl:template>
  
  <!-- Label quantity instructions override the defaults, sets how many copies of the same label will get printed. -->
  <xsl:template name="quantity_instruction">
    <xsl:variable name="value" select="cr:Field/cr:Value/text()" />
    <xsl:attribute name="_QUANTITY">
      <xsl:copy-of select="$value"/>
    </xsl:attribute>
  </xsl:template>


  <!-- Label data specifies which values need to get printed where. -->
  <xsl:template match="cr:Section" mode="data">
    <xsl:variable name="tVal" select="string(cr:Text[1]/cr:TextValue[1]/text())" />
    <xsl:choose>
		<!-- A Section that has its Text/TextValue start with * or '* is an instruction. -->
      <xsl:when test="starts-with($tVal, '*') or starts-with($tVal, '&quot;*') "/>
		<!-- A Section that has its Field@Name set to 'Quantity1' is an instruction. -->
	  <xsl:when test="cr:Field[@Name='Quantity1']"/>
      <xsl:otherwise>
        <xsl:call-template name="field"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Label field specifies which values need to get printed where. 
       Label field gets passed to Loftware as elements named "variable". 
       These have a "name" attribute. This specifies the label field in which to print the data.
       The name comes from the data section's TextValue.
       The value to print comes from the data section's Field Value.
       -->
  <xsl:template name="field">
    <xsl:element name="variable" namespace="{$nsLoft}">
      <xsl:call-template name="fieldNameAttribute"/>
      <xsl:call-template name="fieldValue"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="fieldNameAttribute">
    <xsl:apply-templates select="cr:Text/cr:TextValue"/>
  </xsl:template>

  <!-- This says where (in which label field) some data should get printed. 
       Crystal Reports prints this suffixed by a comma. Lofware does not expect that comma. 
       It must get removed. -->
  <xsl:template match="cr:TextValue">
    <xsl:attribute name="name">
      <!-- This assumes that a field name does not include a comma. -->
      <xsl:copy-of select="substring-before(text(), ',')"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template name="fieldValue">
    <xsl:apply-templates select="cr:Field/cr:FormattedValue"/>
  </xsl:template>

  <xsl:template match="cr:FormattedValue">
    <xsl:copy-of select="text()"/>
  </xsl:template>

</xsl:transform>