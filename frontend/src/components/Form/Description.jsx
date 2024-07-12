
export default function Description({text, children }) {

    return <div style={{
        fontSize: '14px',
        fontWeight: '400',
        lineHeight: '21px',
        color: '#AFB3B7',
        marginBottom: '1rem',
    }}>
        {children}
    </div>
}