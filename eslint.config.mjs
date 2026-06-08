// @ts-check
import withNuxt from './.nuxt/eslint.config.mjs'

export default withNuxt({
  // 你的自定义规则
  rules: {
    'no-debugger': 'error',
  }
})
