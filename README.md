# COVID-19 Care Summary SMART on FHIR Application

_NOTE: This is an early proof-of-concept application, not yet ready for pilot testing._

## About

The COVID-19 Care Summary SMART on FHIR application was developed to support the pilot of CDS artifacts for evidence-based treatment of COVID-19.  This artifact presents a variety of key "factors" for clinicians to consider when assessing the history of a patient's COVID-19 diagnosis and treatment.  These factors include subjective and objective findings, along with recorded treatments and interventions to inform shared decision making on treatments moving forward.

This prototype application is part of the [CDS Connect](https://cds.ahrq.gov/cdsconnect) project, sponsored by the [Agency for Healthcare Research and Quality](https://www.ahrq.gov/) (AHRQ).

## Contributions

For information about contributing to this project, please see [CONTRIBUTING](CONTRIBUTING.md).

## Development Details

The COVID-19 Care Summary is a web-based application implemented with the popular [React](https://reactjs.org/) JavaScript framework. The application adheres to the [SMART on FHIR](https://smarthealthit.org/) standard, allowing it to be integrated into EHR products that support the SMART on FHIR platform. To ensure the best adherence to the standard, the COVID-19 Care Summary application uses the open source [FHIR client](https://github.com/smart-on-fhir/client-js) library provided by the SMART Health IT group.

The logic used to determine what data to display in the COVID-19 Care Summary is defined using [CQL](http://cql.hl7.org/) and integrated into the application as the corresponding JSON ELM representation of the CQL.  The application analyzes the JSON ELM representation to determine what data is needed and then makes the corresponding queries to the FHIR server.

Once the necessary FHIR data has been retrieved from the EHR, the open source [CQL execution engine](https://github.com/cqframework/cql-execution) library is invoked with it and the JSON ELM to calculate the structured summary of the data to display to the user.  This structured summary is then used by the React components to render a user-friendly view of the information.

### To build and run in development:

1. Install [Node.js](https://nodejs.org/en/download/) (LTS edition, currently 12.x)
2. Install [Yarn](https://yarnpkg.com/en/docs/install) (1.3.x or above)
3. Install dependencies by executing `yarn` from the project's root directory
4. If you have a SMART-on-FHIR client ID, edit `public/launch-context.json` to specify it
5. NOTE: The launch context contains `"completeInTarget": true`. This is needed if you are running in an environment that initializes the app in a separate window (such as the public SMART sandbox).  It can be safely removed in other cases.
6. If you'll be launching the app from an Epic EHR, modify `.env` to set `REACT_APP_EPIC_SUPPORTED_QUERIES` to `true`
7. Serve the code by executing `yarn start` (runs on port 8000)

## To build and deploy using a standard web server (static HTML and JS)

The COVID-19 Care Summary can be deployed as static web resources on any HTTP server.  There are several customizations, however, that need to be made based on the site where it is deployed.

1. Install [Node.js](https://nodejs.org/en/download/) (LTS edition, currently 12.x)
2. Install [Yarn](https://yarnpkg.com/en/docs/install) (1.3.x or above)
3. Install dependencies by executing `yarn` from the project's root directory
4. Modify the `homepage` value in `package.json` to reflect the path (after the hostname) at which it will be deployed
   a. For example, if deploying to https://my-server/covid-19-care-summary/, the `homepage` value should be `"http://localhost:8000/covid-19-care-summary"` (note that the hostname need not match)
   b. If deploying to the root of the domain, you can leave `homepage` as `"."`
5. Modify the `clientId` in `public/launch-context.json` to match the unique client ID you registered with the EHR from which this app will be launched
6. NOTE: The launch context contains `"completeInTarget": true`. This is needed if you are running in an environment that initializes the app in a separate window (such as the public SMART sandbox).  It can be safely removed in other cases.
7. If you've set up an analytics endpoint (see below), set the `analytics_endpoint` and `x_api_key` in `public/config.json`
8. If you'll be launching the app from an Epic EHR, modify `.env` to set `REACT_APP_EPIC_SUPPORTED_QUERIES` to `true`
   a. This modifies some queries based on Epic-specific requirements
9. Run `yarn build` to compile the code to static files in the `build` folder
10. Deploy the output from the `build` folder to a standard web server

Optionally to step 9, you can run the static build contents in a simple Node http-server via the command: `yarn start-static`.

### To update the valueset-db.json file

The value set content used by the CQL is cached in a file named `valueset-db.json`.  If the CQL has been modified to add or remove value sets, or if the value sets themselves have been updated, you may wish to update the valueset-db.json with the latest codes.  To do this, you will need a [UMLS Terminology Services account](https://uts.nlm.nih.gov//license.html).

To update the `valueset-db.json` file:

1. Run `node src/utils/updateValueSetDB.js UMLS_USER_NAME UMLS_PASSWORD` _(replacing UMLS\_USER\_NAME and UMLS\_PASSWORD with your username and password)_

## To test the app using the public SMART sandbox

Run the app via one of the options above, then:

1. Browse to http://launch.smarthealthit.org/
2. Select `R4` from the FHIR Version dropdown
3. In the _App Launch URL_ box at the bottom of the page, enter: `http://localhost:8000/launch.html`
4. Click _Launch App!_
5. Select a patient

### To upload test patients to the public SMART sandbox

Testing this SMART App is more meaningful when we can supply test patients that exercise various aspects of the application.  Test patients are represented as FHIR bundles at `src/utils/r4_test_patients`.  To upload the test patients to the public SMART sandbox:

1. Run `yarn upload-test-patients`

This adds a number of patients, mostly with the last name "Jackson" (for example, "Fuller Jackson" has entries in every section of the app).  The SMART sandbox may be reset at any time, so you may need to run this command again if the database has been reset.

### To test the app in standalone mode using the public SMART sandbox

The SMART launcher has a bug that doesn't allow IE 11 to enter the launch URL.  This makes testing in IE 11 very difficult.  To overcome this, you can reconfigure the app as a standalone app.  To do so, follow these steps:

1. Overwrite the `/public/launch-context.json` file with these contents:
   ```json
   {
     "clientId": "6c12dff4-24e7-4475-a742-b08972c4ea27",
     "scope":  "patient/*.read launch/patient",
     "iss": "url-goes-here"
   }
   ```
2. Restart the application server
3. Browse to http://launch.smarthealthit.org/
4. Select `R4` from the FHIR Version dropdown
5. In _Launch Type_, choose **Provider Standalone Launch**
6. Copy the FHIR URL in the _FHIR Server URL_ box at the bottom of the page (e.g., `http://launch.smarthealthit.org/v/r2/sim/eyJoIjoiMSIsImkiOiIxIiwiaiI6IjEifQ/fhir`)
7. Paste it into `/public/launch-context.json` file where `url-goes-here` is
8. Browse to http://localhost:8000/launch.html

_NOTE: Do *not* check in the modified launch-context.json!_
