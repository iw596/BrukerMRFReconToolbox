function eqn = poly_equation(a_hat)
eqn = " y = "+a_hat(1);
for i = 2:(length(a_hat))
    if sign(a_hat(i))>0
        str = " + ";
    else
        str = " ";
    end
    if i == 2
        eqn = eqn+"*x"+str+a_hat(i);
    else
        eqn = eqn+str+a_hat(i)+"*x^"+(i-1)+" ";
    end
end
eqn = eqn+" ";
end