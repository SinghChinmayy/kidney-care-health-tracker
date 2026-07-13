import 'package:app/domain/models/medication.dart';

/// Local catalog of common CKD-related medications.
/// Seeded once when the medications table is empty.
List<Medication> medicationSeedData() {
  final now = DateTime.now().toUtc();
  return [
    Medication(
      id: 'med-furosemide',
      pharmaceuticalName: 'Furosemide',
      composition: 'Furosemide 20 mg / 40 mg / 80 mg tablets',
      about:
          'A loop diuretic used to reduce fluid overload and edema in CKD and '
          'heart failure. Helps the kidneys remove excess salt and water.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-spironolactone',
      pharmaceuticalName: 'Spironolactone',
      composition: 'Spironolactone 25 mg / 50 mg / 100 mg tablets',
      about:
          'A potassium-sparing diuretic and aldosterone antagonist. Used for '
          'edema and blood pressure; potassium levels need close monitoring '
          'in kidney disease.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-amlodipine',
      pharmaceuticalName: 'Amlodipine',
      composition: 'Amlodipine besylate 2.5 mg / 5 mg / 10 mg tablets',
      about:
          'A calcium channel blocker commonly prescribed to lower blood '
          'pressure, which helps protect remaining kidney function.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-ramipril',
      pharmaceuticalName: 'Ramipril',
      composition: 'Ramipril 1.25 mg / 2.5 mg / 5 mg / 10 mg capsules',
      about:
          'An ACE inhibitor that lowers blood pressure and reduces protein '
          'leakage in urine. Often used to slow CKD progression; potassium '
          'and creatinine are monitored.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-sevelamer',
      pharmaceuticalName: 'Sevelamer carbonate',
      composition: 'Sevelamer carbonate 800 mg tablets',
      about:
          'A non-calcium phosphate binder taken with meals to lower high '
          'blood phosphate levels common in advanced CKD and dialysis.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-calcium-acetate',
      pharmaceuticalName: 'Calcium acetate',
      composition: 'Calcium acetate 667 mg capsules',
      about:
          'A calcium-based phosphate binder used with meals to control '
          'hyperphosphatemia in CKD. Calcium levels should be monitored.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-calcitriol',
      pharmaceuticalName: 'Calcitriol',
      composition: 'Calcitriol 0.25 mcg / 0.5 mcg capsules',
      about:
          'Active vitamin D used to treat secondary hyperparathyroidism and '
          'low calcium related to CKD. Dose is adjusted based on labs.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-epoetin',
      pharmaceuticalName: 'Epoetin alfa',
      composition: 'Epoetin alfa injection (various strengths)',
      about:
          'An erythropoiesis-stimulating agent used to treat anemia of CKD '
          'by helping the body make more red blood cells.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-ferrous-sulfate',
      pharmaceuticalName: 'Ferrous sulfate',
      composition: 'Ferrous sulfate 325 mg tablets (≈65 mg elemental iron)',
      about:
          'Oral iron supplement used when iron stores are low, often alongside '
          'treatment for CKD-related anemia.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-sodium-bicarbonate',
      pharmaceuticalName: 'Sodium bicarbonate',
      composition: 'Sodium bicarbonate 650 mg tablets',
      about:
          'Used to correct metabolic acidosis in CKD. Helps keep blood pH in '
          'a healthier range when the kidneys cannot clear acid well.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-kayexalate',
      pharmaceuticalName: 'Sodium polystyrene sulfonate',
      composition: 'Sodium polystyrene sulfonate powder / suspension',
      about:
          'A potassium binder used to lower high blood potassium '
          '(hyperkalemia), a common and serious complication in CKD.',
      createdAt: now,
      updatedAt: now,
    ),
    Medication(
      id: 'med-cinacalcet',
      pharmaceuticalName: 'Cinacalcet',
      composition: 'Cinacalcet hydrochloride 30 mg / 60 mg / 90 mg tablets',
      about:
          'A calcimimetic that lowers parathyroid hormone (PTH), calcium, '
          'and phosphorus in patients with secondary hyperparathyroidism.',
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
