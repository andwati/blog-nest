import { render, screen } from '@testing-library/react'

import Home from './page'

jest.mock('next/image', () => ({
  __esModule: true,
  default: (props: React.ImgHTMLAttributes<HTMLImageElement>) => (
    // biome-ignore lint/a11y/useAltText: mock
    <img {...props} />
  ),
}))

describe('Home', () => {
  it('renders the Next.js logo', () => {
    render(<Home />)
    const logo = screen.getByAltText('Next.js logo')
    expect(logo).toBeInTheDocument()
  })
})
