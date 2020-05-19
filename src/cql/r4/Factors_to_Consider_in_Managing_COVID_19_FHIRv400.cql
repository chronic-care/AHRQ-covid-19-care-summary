// # Introduction

// The COVID-19 Care Summary artifact provides relevant information to consider when managing a patient’s COVID-ID
// diagnosis and care.
// This CDS logic was informed by the Centers for Disease Control and Prevention (CDC) Guideline, but is not a
// direct representation of any one recommendation statement within the guidelines.
// Instead, the CDS compiles clinical concepts mentioned throughout the guidelines in one consolidated summary for
// clinician review.


library Factors_to_Consider_in_Managing_COVID_19_FHIRv400 version '1.0.0'

// # Data model #

using FHIR version '4.0.0'

// # Referenced libraries #

// The CDS Connect Commons for FHIRv400 library provides functions representing commonly used CDS logic and patterns.
include CDS_Connect_Commons_for_FHIRv400 version '1.0.1' called C3F
// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR R4 data model.
include FHIRHelpers version '4.0.0' called FHIRHelpers

// # Value sets and codes #

// ## Code Systems ##

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED-CT": 'http://snomed.info/sct'
codesystem "RxNorm": 'http://www.nlm.nih.gov/research/umls/rxnorm'

// Several concepts needed by the COVID-19 Care Summary CDS do not yet have standardized codes associated with them.
// The CDS logic authors have registered new Logical Object Identifier Names and Codes (LOINC) codes, but they are
// not yet available.  Once available, the CDS will be updated.  Until then, CDS implementors will need to map to
// local codes (signified by the LOCAL code system below) or replace them with their own codes.
codesystem "LOCAL": 'http://cds.ahrq.gov/cdsconnect/ccs'

// ## Value sets ##

// Value sets not available in VSAC, copied via expanded FHIR ValueSet resources

valueset "COVID-19 Comorbidity Risk": 'http://fhir.logicahealth.org/covid19/ValueSet/covid-19-comorbidity-risk-vs'

valueset "C19HCC SARS coronavirus 2 Qualitative Detection Laboratory Tests": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.109'

valueset "COVID-19 Diagnostic Labs": 'http://fhir.logicahealth.org/covid19/ValueSet/covid-19-diagnostic-labs-vs'

// The links to the Value Set Authority Center (VSAC) point to the latest expansion of each value set available.

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1032.117/expansion/Latest)
valueset "Confirmed COVID19 Infection": '2.16.840.1.113762.1.4.1032.117'

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1181.51/expansion/Latest)
valueset "COVID 19 signs and symptoms": '2.16.840.1.113762.1.4.1181.51'

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1032.109/expansion/Latest)
// version attribute is not supported by CodeService
//valueset "C19HCC SARS coronavirus 2 Qualitative Detection Laboratory Tests": '2.16.840.1.113762.1.4.1032.109' version '20200417'

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113883.3.88.12.80.62/expansion/Latest)
valueset "Vital Sign Result Type": '2.16.840.1.113883.3.88.12.80.62'

// Diagnostic lab Tests

valueset "Neutrophil count": '2.16.840.1.113883.3.666.5.1035'

valueset "Bilirubin": '2.16.840.1.113883.3.666.5.2377'

// ## Individual codes ##

// list individual codes from code systems used directly in the CQL logic. Individual codes are used when there is
// a single code from a particular vocabulary standard used to represent a clinical concept. It is considered
// best-practice not to create value sets containing a single code.

//
// TODO the following individual codes support prototype work, will be replaced by Value Sets when available
//

//code "SARS coronavirus 2 RdRp gene [Presence] in Respiratory specimen code":
//  '94534-5' from "LOINC" display 'SARS coronavirus 2 RdRp gene [Presence] in Respiratory specimen by NAA with probe detection'

code "Covid-19 Medications code":
  '979093' from "RxNorm" display 'Hydroxychloroquine Sulfate 200 MG [Plaquenil]'

code "Non pharmacologic treatments for Covid-19 code":
  '371907003' from "SNOMED-CT" display 'Oxygen administration by nasal cannula (procedure)'

// CQL currently requires concept declarations to contain references to code declarations.

//concept "SARS coronavirus 2 RdRp gene [Presence] in Respiratory specimen":
//  { "SARS coronavirus 2 RdRp gene [Presence] in Respiratory specimen code" }
//  display 'SARS coronavirus 2 RdRp gene [Presence] in Respiratory specimen by NAA with probe detection'

concept "Covid-19 Medications":
  { "Covid-19 Medications code" }
  display 'Covid-19 Medications'

concept "Non pharmacologic treatments for Covid-19":
  { "Non pharmacologic treatments for Covid-19 code" }
  display 'Non pharmacologic treatments for Covid-19'

// # Parameters #

// The InclusionMedicationsLookbackPeriod allows CDS implementors to specify how far the inclusion logic should look
// back for qualifying active medications. By default, the inclusion logic will look back 180 days.
parameter InclusionMedicationsLookbackPeriod default 180 days

// # CDS logic #

context Patient

// ## Re-usable functions ##

// The summary logic contains many constructs that are needed throughout the logic. Where possible, these constructs
// have been developed as re-usable functions that can be invoked wherever they are needed.

// Returns the first-found display text for a CodeableConcept, looking first at the `text` attribute, then the
// `display` on each `coding` until it finds a non-null value.
// @param c - a FHIR CodeableConcept to get text from
// @returns {System.String} the display text or null if none is found

define function ConceptText(c FHIR.CodeableConcept):
  Coalesce(c.text.value, Coalesce((c.coding) c2 return c2.display.value))

// Returns a text representation of a date using the CQL `ToString` function.
// @param d - a FHIR date to get text for
// @returns {System.String} the text representation of the date
define function DateText(d FHIR.date):
  ToString(d.value)

// Returns a text representation of a dateTime using the CQL `ToString` function.
// @param d - a FHIR dateTime to get text for
// @returns {System.String} the text representation of the dateTime
define function DateTimeText(d FHIR.dateTime):
  ToString(d.value)

// Returns a text representation of an instant using the CQL `ToString` function.
// @param i - a FHIR instant to get text for
// @returns {System.String} the text representation of the instant
define function InstantText(i FHIR.instant):
  ToString(i.value)

// Returns a text representation of a Quantity with the Quantity's value and unit.
// If the unit is {score}, then omit it (as it is not useful to display)
// @param q - a FHIR Quantity to get text for
// @returns {System.String} the text representation of the Quantity
define function QuantityText(q FHIR.Quantity):
  if (q is null) then null
  else if (q.unit is not null and q.unit.value != '{score}') then ToString(q.value.value) + ' ' + q.unit.value
  else if (q.code is not null and q.code.value != '{score}') then ToString(q.value.value) + ' ' + q.code.value
  else ToString(q.value.value)

// Returns a tuple containing a Period's start and end as text representations.
// @param p - a FHIR Period to get a tuple for
// @returns {Tuple<Start System.String, End System.String>} the tuple representation of the Period
define function PeriodObject(p FHIR.Period):
  if p is null then null
  else
    {
      Start: DateTimeText(p."start"),
      End: DateTimeText(p."end")
    }

// Returns a tuple containing a Range's low and high as text representations.
// @param r - a FHIR Range to get a tuple for
// @returns {Tuple<Low System.String, High System.String>} the tuple representation of the Range
define function RangeObject(r FHIR.Range):
  if r is null then null
  else
    {
      Low: QuantityText(r.low),
      High: QuantityText(r.high)
    }

// Returns a text representation of a date associated with an Observation, preferring `effectiveDateTime`, then
// `effectivePeriod.start`, then `issued`.
// @param o - a FHIR Observation to get the text date from
// @returns {System.String} the text representation of a relevant date from the Observation
define function ObservationDate(o FHIR.Observation):
  Coalesce(
    DateTimeText(o.effective as FHIR.dateTime),
    InstantText(o.effective as FHIR.instant),
    DateTimeText((o.effective as FHIR.Period)."start"),
    InstantText(o.issued)
  )

// Returns a text representation of a date associated with a MedicationStatement, preferring `effectiveDateTime`, then
// `.start`.
// @param s - a FHIR MedicationStatement to get the text date from
// @returns {System.String} the text representation of a relevant date from the MedicationStatement
define function MedicationStatementDate(s FHIR.MedicationStatement):
  Coalesce(
    DateTimeText(s.effective as FHIR.dateTime),
    DateTimeText((s.effective as FHIR.Period)."start")
  )

// Returns a text representation of a Condition's onset, whether represented as a dateTime, Period, Quantity (Age),
// Range (Age), or string.
// @param c - a FHIR Condition to get the text representation of the onset from
// @returns {System.String} the text representation of the Condition's onset
define function Onset(c FHIR.Condition):
  Coalesce( List{
    DateTimeText(c.onset as FHIR.dateTime),
    QuantityText(c.onset as FHIR.Age),
    PeriodObject(c.onset as FHIR.Period),
    RangeObject(c.onset as FHIR.Range),
    (c.onset as FHIR.string).value
  })

// Returns a text representation of a Condition's abatement, whether represented as a dateTime, Period, Quantity (Age),
// Range (Age), string, or boolean.
// @param c - a FHIR Condition to get the text representation of the abatement from
// @returns {System.String} the text representation of the Condition's abatement
define function Abatement(c FHIR.Condition):
  Coalesce( List{
    DateTimeText(c.abatement as FHIR.dateTime),
    QuantityText(c.abatement as FHIR.Age),
    PeriodObject(c.abatement as FHIR.Period),
    RangeObject(c.abatement as FHIR.Range),
    (c.abatement as FHIR.string).value
  })

// ## Target population ##

// INCLUSIONS

// Determines if patient's age, in years, at the time CQL is run, is at least 18 years old
define Is18orOlder:
  AgeInYears() >= 18

// Signs and symptoms of Covid-19
define SignsAndSymptomsOfCovid19:
  C3F.Confirmed(C3F.ActiveOrRecurring([Condition: "COVID 19 signs and symptoms"]))

// Determines if the patient has any of the conditions associated with COVID-19
define HasSignsAndSymptomsOfCovid19:
  exists(SignsAndSymptomsOfCovid19)

// ## Intervention(s) ##

// DISPLAY and POPULATE a COVID-19 Care Summary with the following items:

// PERTINENT MEDICAL HISTORY

// Conditions presenting signs and symptoms of Covid-19 and their dates of onset

define ReportSignsAndSymptomsOfCovid19:
  (SignsAndSymptomsOfCovid19) C
  return {
    Name:   ConceptText(C.code),
    Status: C.clinicalStatus.coding[0].code.value,
    Onset:  Onset(C),
    DateRecorded: DateTimeText(C.recordedDate)
  }
  sort by (Onset as String) desc

// Conditions that are risk factors for opioid-related harms and their dates of onset
// This is a union of nine value sets (w/ different filtering criteria)

define ComorbidityRiskConditions:
  C3F.Confirmed(C3F.ActiveOrRecurring([Condition: "COVID-19 Comorbidity Risk"]))

define Is65orOlder:
  AgeInYears() >= 65

define ConditionRiskFactorsForCovid19:
  ComorbidityRiskConditions

// Encounter diagnoses that are risk factors for opioid-related harms and their dates of onset. Some risk factors may
// not exist on the problem list, and therefore may not be represented as Conditions (depending on EHR implementation).
// For this, the logic also looks at the patient's encounters, trying to find risk factors recorded as encounter
// diagnosis codes. We do not look at the reasonReference field because the Conditions referred to would already be
// reflected in the expression that queries over Conditions.

define EncounterRiskFactorsForCovid19:
  [Encounter] E where exists(
    E.reasonCode R where
      FHIRHelpers.ToConcept(R) in "COVID-19 Comorbidity Risk"
  )

// NOTE: As a convention, if an expression's name starts with "Report", its purpose is to format data for the purpose
// of building the final summary object.

// Format the risk factors in a uniform way despite the different sources of the data (conditions, encounter diagnoses,
// etc.). Note that conditions do not have a "Visit" date and encounter diagnoses do not have a status, onset date,
// recorded date, or abatement date.

define ReportConditionRiskFactorsForCovid19:
  (ConditionRiskFactorsForCovid19) C
  return {
    Name:      ConceptText(C.code),
    Status:    C.clinicalStatus.coding[0].code.value,
    Onset:     Onset(C),
    DateRecorded: DateTimeText(C.recordedDate),
    Abatement: Abatement(C),
    Visit:     null as Tuple{ Start String, End String }
  }
  sort by (Onset as String) desc, (Abatement as String) desc

define function GetEncounterDiagnosesRiskFactorsForCovid19(enc Encounter):
  (enc.reasonCode) R
    where FHIRHelpers.ToConcept(R) in "COVID-19 Comorbidity Risk"
    return {
      Name:      ConceptText(R),
      Status:    null as String,
      Onset:     null as String,
      DateRecorded: null as String,
      Abatement: null as String,
      Visit:     PeriodObject(enc.period)
    }

define ReportEncounterRiskFactorsForCovid19:
  (flatten((EncounterRiskFactorsForCovid19) E
  return GetEncounterDiagnosesRiskFactorsForCovid19(E))) D
  sort by Visit.Start desc, Visit.End desc

// Shape the case of being 65 or older as a Condition for the purposes of building the summary.
define ReportOlderThan65:
  if Is65orOlder then
    {
      Name: '65 years or older',
      Status: 'active',
      Onset: null as String,
      DateRecorded: null as String,
      Abatement: null as String,
      Visit: null as Tuple{ Start String, End String }
    }
  else
    null

define ReportRiskFactorsForCovid19:
  (ReportConditionRiskFactorsForCovid19
    union ReportEncounterRiskFactorsForCovid19
    union ReportOlderThan65) C
  sort by (if Onset is not null then Onset as String else Visit.Start) desc, Visit.End desc, (Abatement as String) desc

// Diagnostic Tests

define LabResultAssessments:
  C3F.Verified(C3F.ObservationLookBack(
    [Observation: "C19HCC SARS coronavirus 2 Qualitative Detection Laboratory Tests"]
      // union [Observation: "SARS coronavirus 2 RdRp gene [Presence] in Respiratory specimen"]
      union [Observation: "COVID-19 Diagnostic Labs"]
      union [Observation: "Neutrophil count"]
      union [Observation: "Bilirubin"],
    1 years
  ))

define VitalSignAssessments:
  C3F.Verified(C3F.ObservationLookBack(
    [Observation: "Vital Sign Result Type"],
    1 years
  ))

define ReportLabResultAssessments:
  (LabResultAssessments) A
  return {
    Name:           ConceptText(A.code),
    Value:          Coalesce( QuantityText(A.value as FHIR.Quantity), ConceptText(A.value as FHIR.CodeableConcept) ),
    Interpretation: Coalesce( ConceptText(First(A.interpretation)),  ConceptText(A.value as FHIR.CodeableConcept) ),
    Date:           ObservationDate(A)
  }
  sort by Date desc

define ReportVitalSignAssessments:
  (VitalSignAssessments) A
  return {
    Name:           ConceptText(A.code),
    Value:          QuantityText(A.value as FHIR.Quantity),
    Interpretation: Coalesce( ConceptText(First(A.interpretation)),  ConceptText(A.value as FHIR.CodeableConcept) ),
    Date:           ObservationDate(A)
  }
  sort by Date desc

// HISTORICAL TREATMENTS

define CovidMedicationRequests:
  C3F.ActiveCompletedOrStoppedMedicationRequest(C3F.MedicationRequestLookBack(
    [MedicationRequest: "Covid-19 Medications"],
    2 years
  ))

define ReportCovidMedications:
  (CovidMedicationRequests) O
  return {
    Type:  'Request',
    Name:  ConceptText(O.medication as FHIR.CodeableConcept),
    Start: DateTimeText(O.authoredOn),
    End:   null as String, // MedicationRequest end date not supported in R4,
    Status: O.status.value
  }
  sort by Start desc, End desc

// Non-pharmacologic treatments, orders, and referrals with dates (lookback 2 years)

define NonPharmacologicTreatmentProcedures:
  C3F.ProcedurePerformance(C3F.ProcedureLookBack([Procedure: "Non pharmacologic treatments for Covid-19"], 2 years))

define ReportNonPharmacologicTreatmentProcedures:
  (NonPharmacologicTreatmentProcedures) P
  return {
    Type: 'Procedure',
    Name: ConceptText(P.code),
    Date: Coalesce(
      DateTimeText(P.performed as FHIR.dateTime),
      DateTimeText((P.performed as FHIR.Period)."start")
    )
  }
  sort by Date desc

define NonPharmacologicTreatmentServiceRequests:
  C3F.ServiceRequestActiveOrCompleted(
    C3F.ServiceRequestLookBack([ServiceRequest: "Non pharmacologic treatments for Covid-19"], 2 years)
  )

define ReportNonPharmacologicTreatmentServiceRequests:
  (NonPharmacologicTreatmentServiceRequests) P
  return {
    Type: 'ServiceRequest',
    Name: ConceptText(P.code),
    Date: DateTimeText(P.authoredOn)
  }
  sort by Date desc

define ReportProceduresAndTherapies:
  (ReportNonPharmacologicTreatmentProcedures
    union ReportNonPharmacologicTreatmentServiceRequests) M
  sort by Date desc


// RISK CONSIDERATIONS

// Hard-coded value for prototype demonstation
define ReportRiskAssessmentRelevantToCovidManagement:
  {
    Name:           'Risk for Acute Respiratory Distress Syndrome (ARDS)',
    Score:          '82%',
    Date:           ToString(Today())
  }


// SUMMARY

// The Summary object represents the full COVID-19 Care Summary to be displayed to the clinician.  All values are
// returned as user-friendly text representations, but a robust user interface (UI) should be implemented to
// display the data to the user in a friendly manner.  See the COVID-19 Care Summary SMART on FHIR application as
// an example of how to integrate this summary into an EHR using modern web UI technologies.

define Summary: {
  Patient: {
    Name: Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '),
    Gender: Patient.gender.value,
    Age: AgeInYears()
  },
  PertinentMedicalHistory: {
    SignsAndSymptomsOfCovid19: ReportSignsAndSymptomsOfCovid19,
    RiskFactorsForCovid19: ReportRiskFactorsForCovid19
  },
  DiagnosticTests: {
    LabResultAssessments: ReportLabResultAssessments,
    VitalSignAssessments: ReportVitalSignAssessments
  },
  HistoricalTreatments: {
    CovidMedications: ReportCovidMedications,
    ProceduresAndTherapies: ReportProceduresAndTherapies
  },
  RiskConsiderations: {
    RiskAssessmentRelevantToCovidManagement: ReportRiskAssessmentRelevantToCovidManagement,
    PatientReportedAssessmentsAndOutcomes: null,
    PatientCenteredSocialNeeds: null
  }
}
