# Repository Guidelines

## Project Structure

This is a Salesforce DX project. Deployable metadata belongs in `force-app/main/default/`, organized by Salesforce type (`classes/`, `triggers/`, `lwc/`, `aura/`, `objects/`, `layouts/`, and related folders). `manifest/package.xml` selects metadata for package operations; `config/` contains scratch-org settings; and `scripts/` holds example Apex and SOQL files. The package directory and Salesforce API version are defined in `sfdx-project.json`. Keep generated files and local org state out of source control.

## Build, Test, and Development

Install dependencies with `npm install` and use Salesforce CLI (`sf`) with an authorized development org for deploy or retrieve operations.

- `npm run lint` checks JavaScript in Aura and LWC components.
- `npm test` runs the LWC Jest unit-test suite; use `npm run test:unit:watch` while developing or `npm run test:unit:coverage` for coverage output.
- `npm run prettier:verify` checks supported source and metadata formatting; run `npm run prettier` to apply formatting.
- `sf project deploy start --manifest manifest/package.xml` deploys the selected metadata to the default org.

## Style and Naming

Follow the repository ESLint rules for Aura/LWC JavaScript and Prettier configuration in `.prettierrc`. Preserve Salesforce metadata naming and folder conventions. Use descriptive camelCase for JavaScript modules and LWC names, PascalCase for Apex classes, and names that describe a trigger's object and purpose. Keep an LWC's HTML, JavaScript, CSS, metadata XML, and tests together under its component folder.

## Testing

Place LWC Jest tests alongside their component in `__tests__` and name them `*.test.js`. Cover observable component behavior and meaningful edge cases. Apex changes should include focused Apex tests in `force-app/main/default/classes`; run them against an authorized org with `sf apex run test`. Run `npm test`, `npm run lint`, and `npm run prettier:verify` for relevant changes before submitting.

## Commits and Pull Requests

The available Git history contains only an initial `first commit`, so no established commit convention can be inferred. Use short imperative subjects (for example, `Add account summary LWC`). Pull requests should explain the behavior changed, list relevant metadata or components, link an issue when applicable, and include test/deployment results. Add screenshots for visible UI changes.

## Configuration and Secrets

Never commit credentials, access tokens, or org-specific secrets. Use Salesforce CLI org authorization locally, and review `manifest/package.xml` and the target org before deploying metadata.
