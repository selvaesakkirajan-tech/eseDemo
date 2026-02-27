# SonarCloud Setup - Step by Step

## ⏱️ Time Required: 15 minutes

Follow these steps in order:

---

## STEP 1: Create SonarCloud Account (2 min)

1. Visit https://sonarcloud.io
2. Click **Sign up**
3. Choose **Sign up with GitHub**
4. Authorize and confirm
5. Create new organization
   - Name: Use your GitHub organization name
   - Key: Keep default
   - Click **Create organization**

---

## STEP 2: Create Token (2 min)

1. Click your profile icon (top right) → **Account**
2. Click **Security** tab
3. Under "Tokens" section, type: `azure-pipelines-token`
4. Click **Generate**
5. **Copy the token** (you'll need this → save in notepad)
6. ✅ Click **Done**

💾 **SAVE THIS TOKEN - you need it in next step!**

---

## STEP 3: Create Azure DevOps Service Connection (3 min)

1. Go to Azure DevOps project
2. Click **Project Settings** (bottom left)
3. Click **Service Connections**
4. Click **New Service Connection** → **Generic**
5. Fill in:
   ```
   Server URL:      https://sonarcloud.io
   Username:        SonarCloud
   Password:        (paste token from STEP 2)
   Service conn name: sonarcloud-connection
   ```
6. Click **Save**

---

## STEP 4: Add Pipeline Variables (3 min)

1. Go to Azure DevOps project
2. Click **Pipelines** → **Library**
3. Click **+ Variable group**
4. Name: `sonarcloud-vars`
5. Add this variable:
   ```
   SONAR_ORG = your-organization-name
   ```
   *(Replace `your-organization-name` with what you entered in STEP 1)*
6. Click **Save**

---

## STEP 5: Run Pipeline (5 min)

1. Go to **Pipelines** → **Runs**
2. Click **Run pipeline**
3. Click **Run**
4. Wait for pipeline to complete (~5-10 min)
5. ✅ Pipeline should pass all quality gates

---

## STEP 6: Check SonarCloud Results (2 min)

1. Go back to https://sonarcloud.io
2. Click your organization
3. You should see **ese-demo-clone** project
4. Click it to see:
   - Code quality status
   - Coverage percentage
   - Security issues
   - Code smells

---

## ✅ DONE!

Your pipeline now has:
- ✅ Unit tests (pytest)
- ✅ Code coverage reporting
- ✅ Code quality analysis (SonarCloud)
- ✅ Security scanning
- ✅ Automatic quality gates

---

## ❓ If Something Goes Wrong

| Issue | Fix |
|-------|-----|
| SonarCloud task fails | Check service connection credentials in STEP 3 |
| "Invalid organization" | Check SONAR_ORG variable matches STEP 1 |
| No coverage data | Coverage is generated automatically - check pipeline logs |
| Quality gate failing | Adjust in SonarCloud dashboard settings |

---

## 📝 Files Updated

- `azure-pipelines.yml` - Added SonarCloud tasks
- `sonar-project.properties` - Configuration (in repo root)
- `apps/python-api/src/requirements.txt` - Added pytest-cov

Done! Now your pipeline has full code quality & security scanning! 🎉

