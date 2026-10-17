\[
     \begin{aligned}
       \sigma_K = 16.000 (\textrm{uint88}) \\
       L(\sigma) = 100.000 = 100.000 \times 1\mathrm{e}8 \\
       \bar L = \frac{L(\sigma)}{\sigma_K^2} \\
       \pi^{\sigma} = \bar L \times (\sigma(i(t))^2 - \sigma_K^2)
      \end{aligned}
\]

Given:



\[
	\begin{aligned}
		\sigma_{W} (t) \equiv \mathrm{Vol} (\mathrm{Window}; t) \, &= (\mathrm{Window})^{-1} \times \sum_{t=t_{\text{now}} - \text{Window}}^{t_{\text{now}}} \Big [i(t_{\text{now}}) \, - \, i_{\mu} (t)\Big ]^2
	\end{aligned}
\]


\[
	\begin{aligned}
		\sigma_{\text{factory}} : T \times \bar \sigma \to \text{TickPath} \equiv \{i\}_{j=0}^{N}
	\end{aligned}
\]

\[
	\begin{aligned}
		\sigma (t_N) = \bar \sigma 
	\end{aligned}
\]

# PRE-REQ

## **Window**
-------
The convention is, lets stablish a fixed time frequency \(\bar dt\). and start \(t_0 \leftarrow \bar t\); This gives:

\[
	\begin{aligned}
		t_1 \leftarrow t_0 + \bar dt \\
		\cdots \\
		t_i \leftarrow t_{i-1} + \bar dt
	\end{aligned}
\]


\[
\begin{aligned}
	\mathrm{Window} = 24\times 60 \times 60
\end{aligned}
\]

\[
	\begin{aligned}
		\textrm{Window} = \sum_{i=0}^{\text{Window}/\bar dt} \bar t_i
	\end{aligned}
\]


## **WeinerGenerator**

 \(\Delta W (t_i) = \sqrt{\bar dt} \, \cdot\, \epsilon \, (t_i); \quad \epsilon (t_i) \sim \mathcal{N} \, (0,1)\)
 
 
# MODEL

Consider a net-flow numeriare diffusion as:

\[
	\begin{aligned}
		\Delta Q_{M} (t_i) \, &= \mu_F \, \bar dt \, + \, \sigma_{F} \, \Delta W (t_i)
	\end{aligned}
\]

------


## **CEVLocalTickVolatility**


\[
	\begin{aligned}
		\sigma (i (t_i)) \, & = \frac{\sigma_F}
{L_{1/2}\ln(1.0001)\sqrt{p (i(t_i))}}\, 
	\end{aligned}
\]


## **CEVLocalTickDrift**


\[
	\begin{aligned}
		\mu (i (t_i))\, &= \, \frac{\mu_F}{L_{1/2}\sqrt{p \, (t_i)}}
-\frac{\sigma_F^2}{2L_{1/2}^2p (i(t_i))}
	\end{aligned}
\]



## **TickDynamics**

\(\Delta i (t_i) \equiv i (t_i) - i (t_{i-1})\);

By making \(\sigma (p) = \delta \, \sqrt{p} \) we have under CPMM, \(\delta = \frac{2\, \sigma_F}{ L_{1/2}}\)


\[
	\begin{aligned}
		\Delta i (t_i) \, = \, \frac{1}{\ln(1.0001)}
\left[
\frac{\mu_F}{L_{1/2}\sqrt{p \, (t_i)}}
-\frac{\sigma_F^2}{2L_{1/2}^2p (t_i)}
\right]\bar{dt}
\\
&+
\frac{\sigma_F}
{L_{1/2}\ln(1.0001)\sqrt{p (t_i)}}
\Delta W (t_i), \\

i(t_i) \, \in \, [i_l, i_u]
	\end{aligned}
\]


since \(i(p(t)) = \log_{1.0001} \sqrt{p(t)} \), then is equivalent to:


\[
	\begin{aligned}
		\Delta p (t_{i}) \, = \, \Big (\frac{2 \, \mu_F}{L_{1/2}} \,\sqrt{p (t_i)} + \, \frac{\sigma_F^2}{(L_{1/2})^2}\Big) \, \bar dt \, + \, \frac{2\, \sigma_F}{ L_{1/2}} \, \sqrt{p (t_i)} \, \Delta \, W (t_i)
	\end{aligned}
\]

### Theorem:

Under CEV, and CPMM \(\textrm{TickPath}\) that realized \(\bar \sigma\) has the endpoint:

\[
	\begin{aligned}
		i(t_N) = \frac{\alpha \, -\, \ln \bar \sigma}{\ln (1.0001)}
	\end{aligned}
\]

#### *Proof*

\[
	\begin{aligned}
		\ln \bigg ( \sigma (i (t_i))\bigg ) &= \ln (\sigma_F) - \Big ( \ln L_{1/2} + \ln \ln 1.0001 + \ln \sqrt{p (i (t_i))}\Big) \\
		&= \, \underbrace{
\ln\left(
\frac{\sigma_F}
{L_{1/2}\ln(1.0001)}
\right)
}_{\alpha}
-
\underbrace{\ln(1.0001)}_{\beta}
\,i(t_i)
	\end{aligned}
\]

So **\(\ln\sigma\) is affine in tick \(i\)**, and, the original nonlinear relation can be recovered as

$$
\boxed{
\sigma (i)=e^{\alpha-\beta \, i}.
}
$$


Then:

\[
	\begin{aligned}
		i(t_N) = \frac{\alpha \, -\, \ln \bar \sigma}{\ln (1.0001)}
	\end{aligned}
\]





