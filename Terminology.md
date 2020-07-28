# COVID-19 Care Summary Terminology and ValueSets

_NOTE: This is an early proof-of-concept application, not yet ready for pilot testing._

## Additional Documentation

* [Overview](README.md) -- Overview of this SMART on FHIR application.
* [Developer Documentation](Developers.md) -- Developer details on the application design and build process.

## Overview

The COVID-19 Care Summary is a web-based application that adheres to the [SMART on FHIR](https://smarthealthit.org/) standard, allowing it to be integrated into EHR products that support the SMART on FHIR platform. The logic used to determine what data to display in the COVID-19 Care Summary is defined using [CQL](http://cql.hl7.org/) which then makes the corresponding queries to the FHIR server. These FHIR data are then used to render a user-friendly view of the information.

### Level 3 heading
