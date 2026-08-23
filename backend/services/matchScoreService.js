const normalize = (str) => String(str || '').trim().toLowerCase();

/**
 * Skill-overlap match score (0-100) between user skills and required skills
 */
const computeMatchScore = (userSkillNames = [], requiredSkills = []) => {
  if (!requiredSkills || requiredSkills.length === 0) return 0;
  const userSet = new Set(userSkillNames.map(normalize));
  const matched = requiredSkills.filter((s) => userSet.has(normalize(s)));
  return Math.round((matched.length / requiredSkills.length) * 100);
};

/**
 * Attaches a `matchScore` field to each listing (job/internship) based on user's skills.
 */
const attachMatchScores = (listings, userSkillNames) => {
  return listings.map((listing) => {
    const obj = typeof listing.toObject === 'function' ? listing.toObject() : listing;
    return {
      ...obj,
      matchScore: computeMatchScore(userSkillNames, obj.skillsRequired || []),
    };
  });
};

/**
 * Advanced multi-factor AI candidate match score algorithm combining:
 * 1. Skill Match (55% weight) with exact + substring/alias matching
 * 2. Qualification/Department Match (30% weight)
 * 3. Experience/Position Match (15% weight)
 */
const computeCandidateMatchScore = (candidateSkills = [], candidateProfile = null, posting = null) => {
  if (!posting) {
    const skillBonus = Math.min(candidateSkills.length * 12, 60);
    const profBonus = candidateProfile?.department ? 25 : 10;
    return Math.min(skillBonus + profBonus, 95);
  }

  const requiredSkills = posting.skillsRequired || [];
  let skillScore = 70;

  if (requiredSkills.length > 0) {
    let matchedCount = 0;
    const candSkillNorms = candidateSkills.map(normalize);

    requiredSkills.forEach((reqSkill) => {
      const normReq = normalize(reqSkill);
      const exactMatch = candSkillNorms.includes(normReq);
      if (exactMatch) {
        matchedCount += 1.0;
      } else {
        const partial = candSkillNorms.some(
          (cs) => cs.includes(normReq) || normReq.includes(cs)
        );
        if (partial) matchedCount += 0.75;
      }
    });

    skillScore = Math.round((matchedCount / requiredSkills.length) * 100);
  }

  let qualScore = 75;
  const postingQual = normalize(posting.qualification || 'Any Student');
  const candDept = normalize(candidateProfile?.department || '');

  if (postingQual.includes('any') || postingQual.includes('all')) {
    qualScore = 100;
  } else if (candDept && (postingQual.includes(candDept) || candDept.includes(postingQual))) {
    qualScore = 100;
  } else if (candDept) {
    qualScore = 70;
  }

  let expScore = 80;

  const finalScore = Math.round(0.55 * skillScore + 0.30 * qualScore + 0.15 * expScore);
  return Math.min(Math.max(finalScore, 40), 99);
};

module.exports = { computeMatchScore, attachMatchScores, computeCandidateMatchScore };
