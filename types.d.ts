
declare module 'pct-encode' {
  export default function createEncoder(replaceThese: RegExp): (s: string) => string
}
