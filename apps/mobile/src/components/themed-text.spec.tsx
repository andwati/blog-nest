import { render, screen } from '@testing-library/react-native'

import { ThemedText } from '@/components/themed-text'

describe('ThemedText', () => {
  it('renders children correctly', () => {
    render(<ThemedText>Hello</ThemedText>)
    expect(screen.getByText('Hello')).toBeTruthy()
  })
})
