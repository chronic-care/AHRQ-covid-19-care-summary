# COVID-19 Care Summary SMART on FHIR Application

_NOTE: This is an early proof-of-concept application, not yet ready for pilot testing._

## About

The COVID-19 Care Summary SMART on FHIR application was developed to support the pilot of CDS artifacts for evidence-based treatment of COVID-19.  This artifact presents a variety of key "factors" for clinicians to consider when assessing the history of a patient's COVID-19 diagnosis and treatment.  These factors include subjective and objective findings, along with recorded treatments and interventions to inform shared decision making on treatments moving forward.

This prototype application is part of the [CDS Connect](https://cds.ahrq.gov/cdsconnect) project, sponsored by the [Agency for Healthcare Research and Quality](https://www.ahrq.gov/) (AHRQ).

## Additional Documentation

* [Developer Documentation](Developers.md) -- Developer details on the application design and build process.
* [Terminology and Value Sets](Terminology.md) -- Use of standardized value sets in this application.

## Overview

The COVID-19 Care Summary is a web-based application that adheres to the [SMART on FHIR](https://smarthealthit.org/) standard, allowing it to be integrated into EHR products that support the SMART on FHIR platform. The logic used to determine what data to display in the COVID-19 Care Summary is defined using [CQL](http://cql.hl7.org/) which then makes the corresponding queries to the FHIR server. These FHIR data are then used to render a user-friendly view of the information.

### Level 3 heading
