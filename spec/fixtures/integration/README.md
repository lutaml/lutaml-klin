# Integration Test Fixtures

This directory contains fixtures for integration testing.

## Purpose

These fixtures provide minimal, realistic test data for end-to-end integration
tests without requiring actual LUR/LXR packages or full ShapeChange
configurations.

## Files

### type_overrides_test.yaml

Sample type override mappings for testing the Type Override Strategy.

Format:
```yaml
type_overrides:
  UmlTypeName: XsdTypeName
```

### shapechange_test_config.yaml

Minimal ShapeChange-style configuration for testing mapping strategies.

Contains:
- Namespace mappings
- Type mappings (XsdMapEntry equivalents)
- Encoding rules

## Usage in Tests

Integration tests use mocked repository adapters rather than actual LUR/LXR
files. These fixtures serve as:

1. **Documentation** - Show expected data formats
2. **Reference** - Provide examples for test data construction
3. **Future expansion** - Can be converted to actual test data if needed

## Test Data Principles

- **Minimal** - Just enough data to verify functionality
- **Realistic** - Follows actual data patterns from PLATEAU, GML, etc.
- **Self-contained** - No external dependencies
- **Documented** - Clear purpose and structure

## Adding New Fixtures

When adding new fixtures:

1. Create a descriptive filename
2. Add documentation in this README
3. Keep files small and focused
4. Use realistic but simplified data