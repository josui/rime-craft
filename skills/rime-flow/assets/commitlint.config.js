export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['add', 'update', 'fix', 'docs', 'style', 'refactor', 'chore'],
    ],
  },
}
