/** @type {import('jest').Config} */
const config = {
  preset: 'jest-expo',
  testRegex: '.*\\.spec\\.tsx?$',
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@sentry/react-native|native-base|react-native-svg)',
  ],
  moduleNameMapper: {
    '\\.(css)$': '<rootDir>/src/__mocks__/styleMock.ts',
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@/assets/(.*)$': '<rootDir>/assets/$1',
  },
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.spec.{ts,tsx}'],
  coverageDirectory: 'coverage',
}

module.exports = config
