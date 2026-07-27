# 📋 Weekly Goals Section Enhancement Plan

## Current State

**Weekly Goals Section shows:**
- Editable weekly goals (default 100/100/100)
- User can manually edit anytime
- No indication these are algorithm-recommended

**Issues:**
- Doesn't reflect personalized recommendations
- Users might not know goals are tailored for them
- Manual editing overrides algorithm suggestions

---

## Proposed Enhancement

After onboarding, the Weekly Goals section should:
1. Show algorithm-recommended goals
2. Indicate these are personalized for the user
3. Still allow editing (user override)
4. Show why these specific numbers were chosen

---

## Implementation Options

### **Option A: Enhanced Display (Recommended)**
Keep existing section but enhance it:

```
Weekly Goals
[Recommended for You badge]

Push-ups: 240 reps ████████░░ 150/240
  Based on your intermediate fitness level

Sit-ups: 300 reps ██████░░░░ 120/300
  Recommended for muscle building

Squats: 360 reps █████████░ 280/360
  Adjusted for your age and activity level

[Edit Goals] button
```

**Changes needed:**
- Add "Recommended for You" badge/indicator
- Show brief explanation under each goal
- Keep edit functionality
- Visual indicator that these are personalized

---

### **Option B: Simplified Display**
Just add a header note:

```
Weekly Goals
💡 Personalized based on your fitness profile

Push-ups: 240 reps ████████░░ 150/240
Sit-ups: 300 reps ██████░░░░ 120/300
Squats: 360 reps █████████░ 280/360

[Edit Goals] button
```

**Changes needed:**
- Add single line explaining personalization
- Minimal code changes
- Quick implementation

---

### **Option C: Two Sections**
Split into "Recommended" and "Your Goals":

```
Recommended Weekly Goals
Based on your fitness assessment

Push-ups: 240 reps
Sit-ups: 300 reps
Squats: 360 reps

[Use These Goals] button

────────────────

Your Current Goals

Push-ups: 200 reps ████████░░ 150/200
...

[Edit Goals] button
```

**Changes needed:**
- Create new "Recommended" section
- Keep existing goals section
- Let user choose to adopt recommendations
- More complex but flexible

---

## Step-by-Step Implementation

Let's go with **Option A** (or you choose!):

### **Step 1: Add Visual Indicator**
- Add "Recommended for You" badge
- Small icon showing it's personalized
- 5 minutes work

### **Step 2: Show Brief Explanation**
- Under each goal, show why it was chosen
- Pull from algorithm multipliers
- 10 minutes work

### **Step 3: Update when plan changes**
- If user retakes assessment, update recommendations
- If user edits profile, recalculate
- 15 minutes work

### **Step 4: Preserve user overrides**
- Track if user manually edited goals
- Don't override their choices automatically
- Show "Using custom goals" indicator
- 20 minutes work

---

## Code Changes Needed

### Minimal (Option B - 5 minutes):
```swift
// Just add a header in ProfileScreen
Text("💡 Personalized based on your fitness profile")
    .font(.caption)
    .foregroundColor(.customSecondaryLabel)
```

### Medium (Option A - 30 minutes):
```swift
// Add badge, explanations, visual indicators
// Update goalProgressCards to show why each goal exists
// Add "Recommended" badge component
```

### Full (Option C - 1 hour):
```swift
// Create new section
// Add button to adopt recommendations
// Track user overrides
// Show comparison between recommended and current
```

---

## What I Recommend

**Start with Option B** (simplest):
1. Add one line saying goals are personalized
2. Takes 2 minutes to implement
3. See if you like it
4. Then we can enhance further

**Then add Option A features** (if you want more):
1. Add visual indicators
2. Show brief explanations
3. Make it really clear why each number was chosen

---

## Questions for You

1. **Which option do you prefer?**
   - A) Enhanced display with explanations
   - B) Simple "personalized" note
   - C) Two separate sections

2. **Should goals auto-update if:**
   - User retakes fitness assessment? (Yes/No)
   - User changes their fitness goal? (Yes/No)
   - User changes activity level? (Yes/No)

3. **Should we preserve manual edits?**
   - If user manually edits goals, don't override them
   - Or always show algorithm recommendations

---

## My Suggestion

**Phase 1 (Now - 5 minutes):**
- Add simple "Recommended for You" note
- Show that goals are from algorithm
- No other changes

**Phase 2 (Later - 20 minutes):**
- Add brief explanation under each goal
- Visual badge or icon
- Make it look polished

**Phase 3 (Optional - 30 minutes):**
- Add "Reset to Recommended" button
- Track if user overrides
- Show comparison view

---

## Example Code Preview

### Simple Version (Phase 1):
```swift
VStack(alignment: .leading, spacing: 16) {
    HStack {
        Text("Weekly Goals")
            .font(.system(size: 18, weight: .bold))
        
        // NEW: Badge
        if workoutViewModel.hasCompletedOnboarding {
            Text("Recommended")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.customOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.customOrange.opacity(0.1))
                .cornerRadius(4)
        }
        
        Spacer()
        
        Button("Edit") { ... }
    }
    
    // NEW: Explanation
    if workoutViewModel.hasCompletedOnboarding {
        Text("💡 Based on your fitness profile and assessment")
            .font(.system(size: 13))
            .foregroundColor(.customSecondaryLabel)
    }
    
    // Existing goal progress cards
    ...
}
```

---

**Let me know which option you prefer and I'll implement it step by step!** 🚀

We can start simple and add more features as we go.

