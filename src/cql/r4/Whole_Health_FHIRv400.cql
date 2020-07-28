// # Introduction

// The Patient-Centered Whole Health Summary artifact provides relevant information to support shared
// decision-making between patients and their care team.

library Whole_Health_FHIRv400 version '1.0.0'

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

codesystem "WHOLEHEALTH": 'http://terminology.va.gov/CodeSystem/personal-health-inventory'

// ## Value sets ##

// Value sets not available in VSAC, included via expanded FHIR ValueSet resources

valueset "Whole Health Self-Care assessments": 'http://va.gov/fhir/ValueSet/personal-health-inventory-self-care'

// ## Individual codes ##

// list individual codes from code systems used directly in the CQL logic. Individual codes are used when there is
// a single code from a particular vocabulary standard used to represent a clinical concept. It is considered
// best-practice not to create value sets containing a single code.

code "Well-Being code":
  'well-being' from "WHOLEHEALTH" display 'Well-Being'
code "Physical Well-Being code":
  'physical-well-being' from "WHOLEHEALTH" display 'Phsical Well-Being'
code "Mental Well-Being code":
  'mental-well-being' from "WHOLEHEALTH" display 'Mental Well-Being'
code "Life Well-Being code":
  'life-well-being' from "WHOLEHEALTH" display 'Life Well-Being'

code "Self-Care Now Rating code":
  'self-care-now-rating' from "WHOLEHEALTH" display 'Where I am Now'
code "Self-Care Future Rating code":
  'self-care-future-rating' from "WHOLEHEALTH" display 'Where I Want to Be'

// CQL currently requires concept declarations to contain references to code declarations.

concept "Well-Being assessment":
  { "Well-Being code" }
  display 'Well-Being'
concept "Physical Well-Being assessment":
  { "Physical Well-Being code" }
  display 'Pysical Well-Being'
concept "Mental Well-Being assessment":
  { "Mental Well-Being code" }
  display 'Mental Well-Being'
concept "Life Well-Being assessment":
  { "Life Well-Being code" }
  display 'Life Well-Being'

concept "Self-Care Now Rating":
  { "Self-Care Now Rating code" } display 'Where I am Now'
concept "Self-Care Future Rating":
  { "Self-Care Future Rating code" } display 'Where I Want to Be'

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
  else if (q.comparator is not null) then q.comparator.value + ' ' + ToString(q.value.value) + ' ' + q.unit.value
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

// Patient-Centered Whole Health

define WellBeingAssessments:
  C3F.ObservationLookBack(
    [Observation: "Well-Being assessment"]
  , 2 year)

define ReportWellBeingAssessments:
  (WellBeingAssessments) A
  let
    Physical: (A.component) C
      where C.code ~ "Physical Well-Being assessment",
    Mental: (A.component) C
      where C.code ~ "Mental Well-Being assessment",
    Life: (A.component) C
      where C.code ~ "Life Well-Being assessment"
  where true // grammar needs a where statement to separate the "let" from the "return"
  return {
    Name:           ConceptText(A.code),
    Questions:      ({ First(Physical), First(Mental), First(Life) }) C
                      where C is not null
                      return { "Name": ConceptText(C.code),
                        "Score": Coalesce(
                          QuantityText(C.value as FHIR.Quantity),
                          ToString(C.value as FHIR.integer)) },
    Date:           ObservationDate(A)
  }
  sort by Date desc

define SelfCareAssessments:
  C3F.ObservationLookBack(
    [Observation: "Whole Health Self-Care assessments"]
  , 2 year)

define ReportSelfCareAssessments:
  (SelfCareAssessments) A
  let
    NowRating: (A.component) C
      where C.code ~ "Self-Care Now Rating",
    FutureRating: (A.component) C
      where C.code ~ "Self-Care Future Rating"
  where true // grammar needs a where statement to separate the "let" from the "return"
  return {
    Name:           ConceptText(A.code),
    Questions:      ({ First(NowRating), First(FutureRating) }) C
                      where C is not null
                      return { "Name": ConceptText(C.code),
                        "Score": Coalesce(
                          QuantityText(C.value as FHIR.Quantity),
                          ToString(C.value as FHIR.integer)) },
    Date:           ObservationDate(A)
  }
  sort by Date desc

define ReportPersonalHealthInventory:
  ReportWellBeingAssessments
    union ReportSelfCareAssessments

// Health Goals by Patient
define PersonalHealthGoals:
  C3F.GoalLookBack(
    [Goal],
    3 years
  )

define ReportPersonalHealthGoals:
  (PersonalHealthGoals) G
  return {
    Description: ConceptText(G.description),
    Type: 'Goal',
    Status: G.lifecycleStatus.value,
    StartDate: DateText(G.start as FHIR.date),
    DueDate: DateText(First((G.target) T return (T.due as FHIR.date))),
    Target: QuantityText(First((G.target) T return (T.detail as FHIR.Quantity)))
  }
  sort by StartDate desc

define ReportPersonalHealthPlan:
  ReportPersonalHealthGoals
